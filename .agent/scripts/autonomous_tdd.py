#!/usr/bin/env python3
"""
Odin AI Agent System - Autonomous TDD (Test-Driven Development)
Otonom Test Döngüsü Yöneticisi

Agent yazdığı kodu otomatik test eder ve başarısız olursa düzeltir.
TDD prensiplerini uygular: Test First → Code → Refactor

Version: 1.0.0
Author: Odin AI System
"""

import subprocess
import json
import re
import sys
import os
from pathlib import Path
from typing import Dict, Any, List, Tuple, Optional, Union
from datetime import datetime
from dataclasses import dataclass, field


# ============================================================================
# DATA CLASSES
# ============================================================================

@dataclass
class TestResult:
    """Test sonucu data class"""
    success: bool
    framework: str
    output: str
    error: Optional[str] = None
    coverage: Optional[float] = None
    duration: Optional[float] = None
    tests_run: int = 0
    tests_failed: int = 0
    tests_passed: int = 0
    test_details: List[Dict[str, Any]] = field(default_factory=list)


@dataclass
class TDDCycleResult:
    """TDD döngüsü sonucu"""
    status: str  # passed, failed, timeout
    attempts: int
    final_code: str
    final_test: str
    test_results: List[TestResult] = field(default_factory=list)
    coverage: Optional[float] = None
    total_duration: float = 0.0
    errors: List[str] = field(default_factory=list)


# ============================================================================
# TEST FRAMEWORK DETECTORS
# ============================================================================

class TestFrameworkDetector:
    """Test framework tespit edici base class"""

    def detect(self, project_path: str) -> Optional[str]:
        """
        Proje dizininde test framework'ı tespit et

        Args:
            project_path: Proje dizini

        Returns:
            Framework adı (jest, pytest, go-test, vb.) veya None
        """
        raise NotImplementedError


class NodeJSTestDetector(TestFrameworkDetector):
    """Node.js / TypeScript test detector"""

    def detect(self, project_path: str) -> Optional[str]:
        """Node.js test framework'ı tespit et"""
        path = Path(project_path)

        # package.json'ı kontrol et
        package_json = path / 'package.json'
        if package_json.exists():
            try:
                with open(package_json, 'r', encoding='utf-8') as f:
                    data = json.load(f)

                dependencies = data.get('dependencies', {})
                dev_dependencies = data.get('devDependencies', {})

                all_deps = {**dependencies, **dev_dependencies}

                # Framework öncelik sırası
                if 'jest' in all_deps:
                    return 'jest'
                if 'vitest' in all_deps:
                    return 'vitest'
                if 'mocha' in all_deps:
                    return 'mocha'
                if '@nestjs/jest' in all_deps:
                    return 'jest'

            except Exception:
                pass

        # Test dosyalarını kontrol et
        test_files = list(path.rglob('*.test.js'))
        test_files.extend(list(path.rglob('*.test.ts')))
        test_files.extend(list(path.rglob('*.spec.js')))
        test_files.extend(list(path.rglob('*.spec.ts')))

        if test_files:
            # Dosya içeriğinden framework tespit etmeye çalış
            for test_file in test_files[:3]:  # İlk 3 dosyayı kontrol et
                try:
                    content = test_file.read_text()

                    if 'describe(' in content or 'describe("' in content:
                        # Jest veya Mocha syntax'ı
                        if 'jest' in content or '@jest/globals' in content:
                            return 'jest'
                        return 'mocha'  # Varsayılan
                except Exception:
                    continue

        return None


class PythonTestDetector(TestFrameworkDetector):
    """Python test detector"""

    def detect(self, project_path: str) -> Optional[str]:
        """Python test framework'ı tespit et"""
        path = Path(project_path)

        # requirements.txt kontrol et
        req_files = [
            path / 'requirements.txt',
            path / 'pyproject.toml',
            path / 'setup.py',
            path / 'Pipfile',
        ]

        for req_file in req_files:
            if req_file.exists():
                try:
                    content = req_file.read_text()

                    if 'pytest' in content:
                        return 'pytest'
                    if 'unittest' in content and 'pytest' not in content:
                        return 'unittest'
                    if 'nose2' in content:
                        return 'nose2'

                except Exception:
                    continue

        # Test dosyalarını kontrol et
        test_files = list(path.rglob('test_*.py'))
        test_files.extend(list(path.rglob('*_test.py')))

        if test_files:
            return 'pytest'  # Varsayılan

        return None


class GoTestDetector(TestFrameworkDetector):
    """Go test detector"""

    def detect(self, project_path: str) -> Optional[str]:
        """Go test framework'ı tespit et"""
        path = Path(project_path)

        # *_test.go dosyalarını ara
        test_files = list(path.rglob('*_test.go'))

        if test_files:
            return 'go-test'

        # go.mod kontrol et
        go_mod = path / 'go.mod'
        if go_mod.exists():
            return 'go-test'

        return None


class RustTestDetector(TestFrameworkDetector):
    """Rust test detector"""

    def detect(self, project_path: str) -> Optional[str]:
        """Rust test framework'ı tespit et"""
        path = Path(project_path)

        # Cargo.toml kontrol et
        cargo_toml = path / 'Cargo.toml'
        if cargo_toml.exists():
            return 'cargo-test'

        # *.rs dosyalarında #[test] ara
        rust_files = list(path.rglob('*.rs'))
        for rust_file in rust_files[:5]:  # İlk 5 dosyayı kontrol et
            try:
                content = rust_file.read_text()
                if '#[test]' in content or '#[cfg(test)]' in content:
                    return 'cargo-test'
            except Exception:
                continue

        return None


# ============================================================================
# TEST RUNNERS
# ============================================================================

class TestRunner:
    """Test runner base class"""

    def __init__(self, timeout: int = 60):
        self.timeout = timeout

    def run_tests(self, project_path: str) -> TestResult:
        """
        Testleri çalıştır

        Args:
            project_path: Proje dizini

        Returns:
            TestResult
        """
        raise NotImplementedError


class JestTestRunner(TestRunner):
    """Jest test runner"""

    def run_tests(self, project_path: str) -> TestResult:
        """Jest testlerini çalıştır"""
        start_time = datetime.now()

        try:
            # Jest çalıştır
            result = subprocess.run(
                [
                    'npm', 'test', '--',
                    '--json', '--outputFile=test-results.json',
                    '--coverage', '--coverageReporters=json',
                    '--coverageReporters=text'
                ],
                cwd=project_path,
                capture_output=True,
                text=True,
                timeout=self.timeout,
                shell=False
            )

            duration = (datetime.now() - start_time).total_seconds()
            output = result.stdout + result.stderr

            # Coverage extract et
            coverage = self._extract_coverage(output)

            # Test sonuçlarını parse et
            tests_run, tests_passed, tests_failed = self._parse_test_results(output)

            if result.returncode == 0:
                return TestResult(
                    success=True,
                    framework='jest',
                    output=output,
                    coverage=coverage,
                    duration=duration,
                    tests_run=tests_run,
                    tests_passed=tests_passed,
                    tests_failed=tests_failed
                )
            else:
                error = self._extract_test_error(output)

                return TestResult(
                    success=False,
                    framework='jest',
                    output=output,
                    error=error,
                    coverage=coverage,
                    duration=duration,
                    tests_run=tests_run,
                    tests_passed=tests_passed,
                    tests_failed=tests_failed
                )

        except subprocess.TimeoutExpired:
            return TestResult(
                success=False,
                framework='jest',
                output='',
                error=f'Test timeout ({self.timeout}s)',
                duration=self.timeout
            )

        except Exception as e:
            return TestResult(
                success=False,
                framework='jest',
                output='',
                error=str(e),
                duration=(datetime.now() - start_time).total_seconds()
            )

    def _extract_coverage(self, output: str) -> Optional[float]:
        """Jest coverage extract et"""
        # "All files" veya "Statements" satırını ara
        match = re.search(r'All files\s+\|\s+([\d.]+)%', output)
        if match:
            return float(match.group(1))

        match = re.search(r'Statements\s+\|\s+([\d.]+)%', output)
        if match:
            return float(match.group(1))

        return None

    def _parse_test_results(self, output: str) -> Tuple[int, int, int]:
        """Test sonuçlarını parse et"""
        # "Tests:       1 passed, 1 failed" formatını ara
        match = re.search(r'Tests:\s+(\d+)\s+(?:passed|PASS),?\s*(\d+)?\s*(?:failed|FAIL)?', output)
        if match:
            passed = int(match.group(1))
            failed = int(match.group(2)) if match.group(2) else 0
            return passed + failed, passed, failed

        # JSON sonuç dosyasını kontrol et
        test_results_file = Path('test-results.json')
        if test_results_file.exists():
            try:
                with open(test_results_file, 'r') as f:
                    data = json.load(f)

                # Jest 27+ format
                if 'testResults' in data:
                    total = len(data['testResults'])
                    passed = sum(1 for r in data['testResults'] if r.get('status') == 'passed')
                    failed = total - passed
                    return total, passed, failed
            except Exception:
                pass

        return 0, 0, 0

    def _extract_test_error(self, output: str) -> str:
        """Jest hata mesajını extract et"""
        # FAIL mesajını bul
        fail_match = re.search(r'FAIL\s+(.*)', output)
        if fail_match:
            return fail_match.group(1)

        # Error mesajını bul
        error_match = re.search(r'Error:\s*(.*?)(?=\n\s*$|\n\s*at\s)', output, re.DOTALL)
        if error_match:
            return error_match.group(1).strip()

        # AssertionError bul
        assert_match = re.search(r'AssertionError:\s*(.*?)(?=\n\s*$|\n\s*at\s)', output, re.DOTALL)
        if assert_match:
            return assert_match.group(1).strip()

        # Son 20 satırı al (genelde hata oradadır)
        lines = output.split('\n')
        return '\n'.join(lines[-20:])


class PytestTestRunner(TestRunner):
    """Pytest test runner"""

    def run_tests(self, project_path: str) -> TestResult:
        """Pytest testlerini çalıştır"""
        start_time = datetime.now()

        try:
            # Pytest çalıştır
            result = subprocess.run(
                [
                    'pytest', '-v', '--tb=short',
                    '--cov-report=json', '--cov-report=term-missing',
                    '--cov='  # Coverage için (paket adı otomatik)
                ],
                cwd=project_path,
                capture_output=True,
                text=True,
                timeout=self.timeout,
                shell=False
            )

            duration = (datetime.now() - start_time).total_seconds()
            output = result.stdout + result.stderr

            # Coverage extract et
            coverage = self._extract_coverage(output)

            # Test sonuçlarını parse et
            tests_run, tests_passed, tests_failed = self._parse_test_results(output)

            if result.returncode == 0:
                return TestResult(
                    success=True,
                    framework='pytest',
                    output=output,
                    coverage=coverage,
                    duration=duration,
                    tests_run=tests_run,
                    tests_passed=tests_passed,
                    tests_failed=tests_failed
                )
            else:
                error = self._extract_test_error(output)

                return TestResult(
                    success=False,
                    framework='pytest',
                    output=output,
                    error=error,
                    coverage=coverage,
                    duration=duration,
                    tests_run=tests_run,
                    tests_passed=tests_passed,
                    tests_failed=tests_failed
                )

        except subprocess.TimeoutExpired:
            return TestResult(
                success=False,
                framework='pytest',
                output='',
                error=f'Test timeout ({self.timeout}s)',
                duration=self.timeout
            )

        except FileNotFoundError:
            # Pytest yüklü değil
            return TestResult(
                success=False,
                framework='pytest',
                output='',
                error='pytest yüklü değil. Kurulum: pip install pytest pytest-cov',
                duration=(datetime.now() - start_time).total_seconds()
            )

        except Exception as e:
            return TestResult(
                success=False,
                framework='pytest',
                output='',
                error=str(e),
                duration=(datetime.now() - start_time).total_seconds()
            )

    def _extract_coverage(self, output: str) -> Optional[float]:
        """Pytest coverage extract et"""
        # Coverage satırını ara
        match = re.search(r'TOTAL\s+(\d+)\s+(\d+)\s+(\d+)%', output)
        if match:
            return float(match.group(3))

        # coverage.json dosyasını kontrol et
        coverage_file = Path('coverage.json')
        if coverage_file.exists():
            try:
                with open(coverage_file, 'r') as f:
                    data = json.load(f)

                totals = data.get('totals', {})
                percent_covered = totals.get('percent_covered')
                if percent_covered:
                    return float(percent_covered)
            except Exception:
                pass

        return None

    def _parse_test_results(self, output: str) -> Tuple[int, int, int]:
        """Pytest test sonuçlarını parse et"""
        # "X passed, Y failed" formatını ara
        match = re.search(r'(\d+)\s+passed,\s+(\d+)\s+failed', output)
        if match:
            passed = int(match.group(1))
            failed = int(match.group(2))
            return passed + failed, passed, failed

        # "X passed" formatını ara
        match = re.search(r'(\d+)\s+passed', output)
        if match:
            passed = int(match.group(1))
            return passed, passed, 0

        # "::PASSED" ve "::FAILED" formatını ara (pytest -v)
        passed = len(re.findall(r'::PASSED', output))
        failed = len(re.findall(r'::FAILED', output))

        if passed > 0 or failed > 0:
            return passed + failed, passed, failed

        return 0, 0, 0

    def _extract_test_error(self, output: str) -> str:
        """Pytest hata mesajını extract et"""
        # FAILED mesajını bul
        fail_match = re.search(r'FAILED\s+(.*)', output)
        if fail_match:
            return fail_match.group(1)

        # AssertionError bul
        assert_match = re.search(r'AssertionError:\s*(.*?)(?=\n\s*$|\n\s*test)', output, re.DOTALL)
        if assert_match:
            return assert_match.group(1).strip()

        # Son 30 satırı al
        lines = output.split('\n')
        return '\n'.join(lines[-30:])


class GoTestRunner(TestRunner):
    """Go test runner"""

    def run_tests(self, project_path: str) -> TestResult:
        """Go testlerini çalıştır"""
        start_time = datetime.now()

        try:
            # Go test çalıştır
            result = subprocess.run(
                ['go', 'test', '-v', '-coverprofile=coverage.out', '-covermode=atomic'],
                cwd=project_path,
                capture_output=True,
                text=True,
                timeout=self.timeout,
                shell=False,
                env={**os.environ, 'GO111MODULE': 'on'}
            )

            duration = (datetime.now() - start_time).total_seconds()
            output = result.stdout + result.stderr

            # Coverage extract et
            coverage = self._extract_coverage(output)

            # Test sonuçlarını parse et
            tests_run, tests_passed, tests_failed = self._parse_test_results(output)

            if result.returncode == 0:
                return TestResult(
                    success=True,
                    framework='go-test',
                    output=output,
                    coverage=coverage,
                    duration=duration,
                    tests_run=tests_run,
                    tests_passed=tests_passed,
                    tests_failed=tests_failed
                )
            else:
                error = self._extract_test_error(output)

                return TestResult(
                    success=False,
                    framework='go-test',
                    output=output,
                    error=error,
                    coverage=coverage,
                    duration=duration,
                    tests_run=tests_run,
                    tests_passed=tests_passed,
                    tests_failed=tests_failed
                )

        except subprocess.TimeoutExpired:
            return TestResult(
                success=False,
                framework='go-test',
                output='',
                error=f'Test timeout ({self.timeout}s)',
                duration=self.timeout
            )

        except FileNotFoundError:
            return TestResult(
                success=False,
                framework='go-test',
                output='',
                error='go yüklü değil',
                duration=(datetime.now() - start_time).total_seconds()
            )

        except Exception as e:
            return TestResult(
                success=False,
                framework='go-test',
                output='',
                error=str(e),
                duration=(datetime.now() - start_time).total_seconds()
            )

    def _extract_coverage(self, output: str) -> Optional[float]:
        """Go coverage extract et"""
        match = re.search(r'coverage:\s+([\d.]+)%', output)
        if match:
            return float(match.group(1))
        return None

    def _parse_test_results(self, output: str) -> Tuple[int, int, int]:
        """Go test sonuçlarını parse et"""
        # "PASS: TestName" ve "FAIL: TestName" formatlarını ara
        passed = len(re.findall(r'PASS:\s+\S+', output))
        failed = len(re.findall(r'FAIL:\s+\S+', output))

        if passed > 0 or failed > 0:
            return passed + failed, passed, failed

        # "--- FAIL: TestName" formatını ara
        failed = len(re.findall(r'--- FAIL:\s+\S+', output))

        # "ok\tTestName" formatını ara
        passed = len(re.findall(r'^ok\t', output, re.MULTILINE))

        return passed + failed, passed, failed

    def _extract_test_error(self, output: str) -> str:
        """Go test hata mesajını extract et"""
        # FAIL mesajını bul
        fail_match = re.search(r'--- FAIL:\s+(.*?)(?=\n\s*$|\n\s+---)', output, re.DOTALL)
        if fail_match:
            return fail_match.group(1).strip()

        # Error mesajını bul
        error_match = re.search(r'Error:\s*(.*?)(?=\n\s*$|\n\s+at\s)', output, re.DOTALL)
        if error_match:
            return error_match.group(1).strip()

        # Son 30 satırı al
        lines = output.split('\n')
        return '\n'.join(lines[-30:])


class CargoTestRunner(TestRunner):
    """Cargo test runner (Rust)"""

    def run_tests(self, project_path: str) -> TestResult:
        """Cargo testlerini çalıştır"""
        start_time = datetime.now()

        try:
            # Cargo test çalıştır
            result = subprocess.run(
                ['cargo', 'test', '--', '--nocapture'],
                cwd=project_path,
                capture_output=True,
                text=True,
                timeout=self.timeout,
                shell=False
            )

            duration = (datetime.now() - start_time).total_seconds()
            output = result.stdout + result.stderr

            # Coverage extract et (grcov veya tarpaulin gerekli)
            coverage = None  # Rust için native coverage yok

            # Test sonuçlarını parse et
            tests_run, tests_passed, tests_failed = self._parse_test_results(output)

            if result.returncode == 0:
                return TestResult(
                    success=True,
                    framework='cargo-test',
                    output=output,
                    coverage=coverage,
                    duration=duration,
                    tests_run=tests_run,
                    tests_passed=tests_passed,
                    tests_failed=tests_failed
                )
            else:
                error = self._extract_test_error(output)

                return TestResult(
                    success=False,
                    framework='cargo-test',
                    output=output,
                    error=error,
                    coverage=coverage,
                    duration=duration,
                    tests_run=tests_run,
                    tests_passed=tests_passed,
                    tests_failed=tests_failed
                )

        except subprocess.TimeoutExpired:
            return TestResult(
                success=False,
                framework='cargo-test',
                output='',
                error=f'Test timeout ({self.timeout}s)',
                duration=self.timeout
            )

        except FileNotFoundError:
            return TestResult(
                success=False,
                framework='cargo-test',
                output='',
                error='cargo yüklü değil',
                duration=(datetime.now() - start_time).total_seconds()
            )

        except Exception as e:
            return TestResult(
                success=False,
                framework='cargo-test',
                output='',
                error=str(e),
                duration=(datetime.now() - start_time).total_seconds()
            )

    def _parse_test_results(self, output: str) -> Tuple[int, int, int]:
        """Cargo test sonuçlarını parse et"""
        # "test result: ok" ve "test result: FAILED" formatlarını ara
        passed = len(re.findall(r'test result:\s+ok', output))
        failed = len(re.findall(r'test result:\s+FAILED', output))

        return passed + failed, passed, failed

    def _extract_test_error(self, output: str) -> str:
        """Cargo test hata mesajını extract et"""
        # "FAILED" mesajını bul
        fail_match = re.search(r'test result:\s+FAILED\s*(.*?)(?=\n\s*$|\n\s*---)', output, re.DOTALL)
        if fail_match:
            return fail_match.group(1).strip()

        # "panicked at" mesajını bul
        panic_match = re.search(r'panicked at\s+(.*?)(?=\n\s*$)', output, re.DOTALL)
        if panic_match:
            return f"Panic: {panic_match.group(1).strip()}"

        # Son 30 satırı al
        lines = output.split('\n')
        return '\n'.join(lines[-30:])


# ============================================================================
# AUTONOMOUS TDD MANAGER
# ============================================================================

class AutonomousTDD:
    """
    Otonom Test Döngüsü Yöneticisi

    Agent yazdığı kodu otomatik test eder ve
    başarısız olursa düzeltir.
    """

    def __init__(
        self,
        max_retries: int = 3,
        test_timeout: int = 60,
        auto_fix: bool = True
    ):
        """
        AutonomousTDD başlat

        Args:
            max_retries: Maksimum deneme sayısı
            test_timeout: Test timeout (saniye)
            auto_fix: Otomatik düzeltme açık mı?
        """
        self.max_retries = max_retries
        self.test_timeout = test_timeout
        self.auto_fix = auto_fix

        # Detector'lar
        self.detectors = [
            NodeJSTestDetector(),
            PythonTestDetector(),
            GoTestDetector(),
            RustTestDetector(),
        ]

        # Runner'lar
        self.runners = {
            'jest': JestTestRunner(test_timeout),
            'vitest': JestTestRunner(test_timeout),  # Vitest Jest ile aynı API
            'mocha': JestTestRunner(test_timeout),
            'pytest': PytestTestRunner(test_timeout),
            'go-test': GoTestRunner(test_timeout),
            'cargo-test': CargoTestRunner(test_timeout),
        }

    def detect_framework(self, project_path: str) -> Optional[str]:
        """
        Proje dizininde test framework'ı tespit et

        Args:
            project_path: Proje dizini

        Returns:
            Framework adı veya None
        """
        path = Path(project_path)

        if not path.exists():
            return None

        for detector in self.detectors:
            framework = detector.detect(project_path)
            if framework:
                return framework

        return None

    def run_tests(self, project_path: str, framework: Optional[str] = None) -> TestResult:
        """
        Testleri çalıştır

        Args:
            project_path: Proje dizini
            framework: Framework adı (None ise otomatik tespit)

        Returns:
            TestResult
        """
        # Framework tespit et
        if framework is None:
            framework = self.detect_framework(project_path)

        if framework is None:
            return TestResult(
                success=False,
                framework='unknown',
                output='',
                error='Test framework tespit edilemedi. Jest, Pytest, Go test veya Cargo test projesi olduğundan emin olun.'
            )

        # Runner'ı al
        runner = self.runners.get(framework)

        if runner is None:
            return TestResult(
                success=False,
                framework=framework,
                output='',
                error=f'{framework} için test runner implement edilmedi.'
            )

        # Test çalıştır
        return runner.run_tests(project_path)

    def execute_tdd_cycle(
        self,
        project_path: str,
        max_attempts: Optional[int] = None
    ) -> TDDCycleResult:
        """
        TDD döngüsünü çalıştır

        Args:
            project_path: Proje dizini
            max_attempts: Maksimum deneme sayısı (None ise self.max_retries)

        Returns:
            TDDCycleResult
        """
        if max_attempts is None:
            max_attempts = self.max_retries

        result = TDDCycleResult(
            status='unknown',
            attempts=0,
            final_code='',
            final_test=''
        )

        print(f"🧪 TDD Döngüsü Başlatılıyor (max {max_attempts} deneme)...")
        print(f"📂 Proje: {project_path}")

        # Framework tespit et
        framework = self.detect_framework(project_path)

        if framework is None:
            print(f"❌ Test framework tespit edilemedi")
            result.status = 'failed'
            result.errors.append('Test framework bulunamadı')
            return result

        print(f"🔧 Framework: {framework}")

        # Test döngüsü
        for attempt in range(1, max_attempts + 1):
            print(f"\n📝 Deneme {attempt}/{max_attempts}")

            # Test çalıştır
            test_result = self.run_tests(project_path, framework)
            result.test_results.append(test_result)
            result.attempts = attempt
            result.total_duration += test_result.duration or 0

            # Sonucu raporla
            if test_result.success:
                # ✅ Test geçti
                result.status = 'passed'
                result.coverage = test_result.coverage

                print(f"✅ Test PASSED!")
                print(f"   Coverage: {test_result.coverage}%")
                print(f"   Tests: {test_result.tests_passed}/{test_result.tests_run}")
                print(f"   Duration: {test_result.duration:.2f}s")

                break

            else:
                # ❌ Test başarısız
                error = test_result.error or 'Bilinmeyen hata'
                result.errors.append(error)

                print(f"❌ Test FAILED: {error}")

                if attempt < max_attempts and self.auto_fix:
                    print(f"🔧 Düzeltiliyor...")

                    # Agent'ten düzeltme iste (Bu kısım Claude'dan çağrılacak)
                    # NOT: Gerçek implementasyon için Agent entegrasyonu gerek
                    # Şimdilik bekleme
                    import time
                    time.sleep(1)  # Simüle edilmiş bekleme

                else:
                    # Max retry aşıldı veya auto_fix kapalı
                    result.status = 'failed'
                    print(f"❌ {max_attempts} denemeden sonra başarısız")
                    break

        return result


# ============================================================================
# CLI
# ============================================================================

def print_success(msg: str):
    print(f"✅ {msg}")


def print_error(msg: str):
    print(f"❌ {msg}")


def print_warning(msg: str):
    print(f"⚠️  {msg}")


def print_info(msg: str):
    print(f"ℹ️  {msg}")


def cmd_detect(args):
    """Test framework tespiti"""
    project_path = args[0] if args else '.'

    tdd = AutonomousTDD()
    framework = tdd.detect_framework(project_path)

    if framework:
        print_success(f"Framework tespit edildi: {framework}")
        return 0
    else:
        print_warning("Test framework tespit edilemedi")
        return 1


def cmd_test(args):
    """Testleri çalıştır"""
    project_path = args[0] if args else '.'
    framework = args[1] if len(args) > 1 else None

    print_info(f"Test çalıştırılıyor: {project_path}")

    tdd = AutonomousTDD()
    result = tdd.run_tests(project_path, framework)

    print()
    if result.success:
        print_success("Test PASSED")
        print(f"   Framework: {result.framework}")
        print(f"   Tests: {result.tests_passed}/{result.tests_run}")
        if result.coverage:
            print(f"   Coverage: {result.coverage}%")
        print(f"   Duration: {result.duration:.2f}s")
        return 0
    else:
        print_error("Test FAILED")
        print(f"   Framework: {result.framework}")
        print(f"   Error: {result.error}")
        print()
        print("Output:")
        print(result.output[:500])  # İlk 500 karakter
        return 1


def cmd_cycle(args):
    """TDD döngüsünü çalıştır"""
    project_path = args[0] if args else '.'
    max_attempts = int(args[1]) if len(args) > 1 else None

    tdd = AutonomousTDD()
    result = tdd.execute_tdd_cycle(project_path, max_attempts)

    print()
    print("📊 TDD Döngüsü Sonucu:")
    print()
    print(f"   Durum: {result.status}")
    print(f"   Denemeler: {result.attempts}")
    print(f"   Toplam süre: {result.total_duration:.2f}s")

    if result.coverage:
        print(f"   Coverage: {result.coverage}%")

    if result.errors:
        print()
        print("   Hatalar:")
        for error in result.errors:
            print(f"   • {error}")

    if result.status == 'passed':
        return 0
    else:
        return 1


def cmd_help():
    """Yardım menüsü"""
    print("""
Odin AI Agent System - Autonomous TDD (Test-Driven Development)

Kullanım:
  python autonomous_tdd.py <command> [args]

Komutlar:
  detect <project_path>   Test framework tespiti
  test <project_path> [framework]  Testleri çalıştır
  cycle <project_path> [max_attempts]  TDD döngüsünü çalıştır
  help                  Bu yardım menüsü

Örnekler:
  # Framework tespiti
  python autonomous_tdd.py detect .

  # Test çalıştır (otomatik framework tespiti)
  python autonomous_tdd.py test .

  # TDD döngüsü (max 5 deneme)
  python autonomous_tdd.py cycle . 5

Desteklenen Framework'ler:
  • JavaScript/TypeScript: Jest, Vitest, Mocha
  • Python: Pytest
  • Go: go test
  • Rust: cargo test
    """)


def main():
    """CLI entry point"""
    if len(sys.argv) < 2:
        cmd_help()
        return 1

    command = sys.argv[1]
    args = sys.argv[2:]

    commands = {
        'detect': cmd_detect,
        'test': cmd_test,
        'cycle': cmd_cycle,
        'help': cmd_help,
    }

    if command not in commands:
        print_error(f"Bilinmeyen komut: {command}")
        cmd_help()
        return 1

    return commands[command](args)


if __name__ == '__main__':
    sys.exit(main())
