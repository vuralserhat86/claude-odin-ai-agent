#!/usr/bin/env python3
"""
ODIN AI Agent System - Project Scanner
Proje dilini, framework'ünü, dosya ağacını tarar ve özet çıkarar.

Version: 1.0.0
"""

import os
import json
import re
from pathlib import Path
from typing import Dict, List, Optional, Any
from datetime import datetime


class ProjectScanner:
    """Proje tarayıcı sınıfı"""

    def __init__(self, project_root: str = "."):
        self.project_root = Path(project_root).resolve()
        self.scan_results = {
            "scan_date": datetime.now().isoformat(),
            "project_root": str(self.project_root),
            "language": None,
            "framework": None,
            "package_manager": None,
            "tech_stack": [],
            "file_structure": {},
            "summary": ""
        }

    def scan(self) -> Dict[str, Any]:
        """Projesini tara ve sonuçları döndür"""
        print(f"🔍 Proje taranıyor: {self.project_root}")

        # 1. Dil tespiti
        self._detect_language()

        # 2. Framework tespiti
        self._detect_framework()

        # 3. Package manager tespiti
        self._detect_package_manager()

        # 4. Tech stack tespiti
        self._detect_tech_stack()

        # 5. Dosya yapısı taraması
        self._scan_file_structure()

        # 6. Özet oluştur
        self._generate_summary()

        return self.scan_results

    def _detect_language(self):
        """Proje dilini tespit et"""
        language_indicators = [
            ("Python", [".py", "requirements.txt", "setup.py", "pyproject.toml", "Pipfile"]),
            ("JavaScript/TypeScript", [".js", ".ts", ".jsx", ".tsx", "package.json", "tsconfig.json"]),
            ("Go", [".go", "go.mod", "go.sum"]),
            ("Rust", [".rs", "Cargo.toml", "Cargo.lock"]),
            ("Java", [".java", "pom.xml", "build.gradle", "src/main/java"]),
            ("C#", [".cs", ".csproj", "sln"]),
            ("Ruby", [".rb", "Gemfile", "Rakefile"]),
            ("PHP", [".php", "composer.json"]),
        ]

        detected_languages = []

        for lang, indicators in language_indicators:
            for indicator in indicators:
                # Dosya uzantısı için wildcard ekle
                pattern = f"*{indicator}" if indicator.startswith('.') else indicator
                if any(self.project_root.rglob(pattern)):
                    detected_languages.append(lang)
                    break

        if detected_languages:
            self.scan_results["language"] = detected_languages[0] if len(detected_languages) == 1 else "Multi-language"
            print(f"   ✓ Dil: {self.scan_results['language']}")
        else:
            self.scan_results["language"] = "Unknown"
            print(f"   ⚠ Dil tespit edilemedi")

    def _detect_framework(self):
        """Framework tespit et"""
        framework_indicators = [
            ("Next.js", ["next.config.js", "next.config.mjs"]),
            ("React", ["package.json"]),  # package.json içinde "react" kontrolü
            ("Vue", ["vue.config.js", "vite.config.js"]),
            ("Angular", ["angular.json"]),
            ("Svelte", ["svelte.config.js"]),
            ("Django", ["manage.py", "settings.py"]),
            ("Flask", ["app.py", "wsgi.py"]),
            ("FastAPI", ["main.py"]),  # fastapi import kontrolü
            ("Express", ["package.json"]),  # express kontrolü
            ("NestJS", ["nest-cli.json"]),
            ("Spring Boot", ["pom.xml", "build.gradle"]),
            ("Rails", ["Gemfile", "config/application.rb"]),
            ("Laravel", ["artisan", "app/Http/Controllers"]),
            # Mobile
            ("React Native", ["react-native.config.js", "app.json"]),
            ("Flutter", ["pubspec.yaml", "lib/main.dart"]),
            # Desktop
            ("Electron", ["electron", "electron-builder"]),
        ]

        detected_frameworks = []

        for framework, indicators in framework_indicators:
            for indicator in indicators:
                # package.json özel kontrolü
                if indicator == "package.json":
                    package_json = self.project_root / "package.json"
                    if package_json.exists():
                        content = package_json.read_text()
                        if framework in ["React", "Express"]:
                            if framework.lower() in content.lower():
                                detected_frameworks.append(framework)
                        elif "next" in content.lower():
                            detected_frameworks.append("Next.js")
                else:
                    # Dosya uzantısı için wildcard ekle
                    pattern = f"*{indicator}" if indicator.startswith('.') else indicator
                    if any(self.project_root.rglob(pattern)):
                        detected_frameworks.append(framework)
                        break

        if detected_frameworks:
            self.scan_results["framework"] = detected_frameworks[0] if len(detected_frameworks) == 1 else detected_frameworks
            print(f"   ✓ Framework: {self.scan_results['framework']}")
        else:
            self.scan_results["framework"] = "Unknown"
            print(f"   ⚠ Framework tespit edilemedi")

    def _detect_package_manager(self):
        """Package manager tespit et"""
        package_managers = [
            ("npm", ["package.json", "package-lock.json"]),
            ("yarn", ["yarn.lock"]),
            ("pnpm", ["pnpm-lock.yaml"]),
            ("pip", ["requirements.txt", "setup.py", "pyproject.toml", "Pipfile", "poetry.lock"]),
            ("poetry", ["pyproject.toml", "poetry.lock"]),
            ("go_modules", ["go.mod"]),
            ("cargo", ["Cargo.toml", "Cargo.lock"]),
            ("composer", ["composer.json", "composer.lock"]),
            ("bundler", ["Gemfile", "Gemfile.lock"]),
            ("maven", ["pom.xml"]),
            ("gradle", ["build.gradle", "build.gradle.kts"]),
        ]

        for pm, indicators in package_managers:
            # Herhangi bir indicator dosyası var mı kontrol et
            for indicator in indicators:
                # Proje root'unda veya herhangi bir alt dizinde ara
                if (self.project_root / indicator).exists() or any(self.project_root.rglob(f"*/{indicator}")):
                    self.scan_results["package_manager"] = pm
                    print(f"   ✓ Package Manager: {pm}")
                    return

        self.scan_results["package_manager"] = "Unknown"
        print(f"   ⚠ Package manager tespit edilemedi")

    def _detect_tech_stack(self):
        """Tech stack tespit et"""
        tech_stack = []

        # Config dosyalarını tara
        config_files = list(self.project_root.rglob("*.json")) + \
                       list(self.project_root.rglob("*.yaml")) + \
                       list(self.project_root.rglob("*.yml")) + \
                       list(self.project_root.rglob("*.toml")) + \
                       list(self.project_root.rglob("*.config.*"))

        # Klasör yapısından bilgi çıkar
        dirs = [d.name for d in self.project_root.iterdir() if d.is_dir()]

        # Web projesi indicator'ları
        web_indicators = {
            "pages": "Next.js Pages Router",
            "app": "Next.js App Router",
            "src": "Source directory",
            "components": "React components",
            "hooks": "React hooks",
            "utils": "Utilities",
            "lib": "Library",
            "styles": "Styles",
            "public": "Public assets",
            "tests": "Tests",
            "__tests__": "Tests",
            "test": "Tests",
            "api": "API routes",
            "server": "Server code",
            "backend": "Backend code",
            "frontend": "Frontend code",
        }

        for dir_name, desc in web_indicators.items():
            if dir_name in dirs:
                tech_stack.append(f"Directory: {dir_name} ({desc})")

        # Config dosyalarından tech stack çıkar
        for config_file in config_files[:20]:  # İlk 20 dosya
            if config_file.name == "package.json":
                try:
                    content = json.loads(config_file.read_text())
                    deps = content.get("dependencies", {}) | content.get("devDependencies", {})
                    tech_stack.extend(list(deps.keys())[:10])  # İlk 10 dependency
                except:
                    pass

        self.scan_results["tech_stack"] = tech_stack
        print(f"   ✓ Tech Stack: {len(tech_stack)} bileşen tespit edildi")

    def _scan_file_structure(self):
        """Dosya yapısını tara"""
        file_count = 0
        dir_count = 0
        extensions = {}

        # İlk 2 derinlikte tara
        for item in self.project_root.rglob("*"):
            if item.is_file():
                file_count += 1
                ext = item.suffix
                if ext:
                    extensions[ext] = extensions.get(ext, 0) + 1

                # Performans için ilk 1000 dosya
                if file_count >= 1000:
                    break
            elif item.is_dir():
                # .git, node_modules, __pycache__ gibi dizinleri atla
                if not any(part.startswith('.') for part in item.parts):
                    dir_count += 1

        self.scan_results["file_structure"] = {
            "file_count": file_count,
            "dir_count": dir_count,
            "extensions": dict(sorted(extensions.items(), key=lambda x: x[1], reverse=True)[:20])
        }

        print(f"   ✓ Dosya Yapısı: {file_count} dosya, {dir_count} klasör")

    def _generate_summary(self):
        """Özet oluştur"""
        lang = self.scan_results["language"]
        framework = self.scan_results["framework"]
        pm = self.scan_results["package_manager"]
        file_count = self.scan_results["file_structure"]["file_count"]

        summary = f"""Bu bir {lang} projesidir"""

        if framework != "Unknown":
            summary += f", {framework} framework'ü kullanıyor"

        if pm != "Unknown":
            summary += f" ve {pm} package manager'ı ile yönetiliyor"

        summary += f". Toplam {file_count} dosya bulunuyor."

        self.scan_results["summary"] = summary
        print(f"\n   📋 ÖZET: {summary}")

    def save_context(self, output_file: str = ".agent/context.md"):
        """Context dosyasını kaydet"""
        context_content = f"""# Project Context (Auto-Generated)

> **Generated:** {self.scan_results['scan_date']}
> **Scanner:** ODIN Project Scanner v1.0.0

---

## 📊 Project Overview

{self.scan_results['summary']}

---

## 🔧 Technical Details

| Property | Value |
|----------|-------|
| **Language** | {self.scan_results['language']} |
| **Framework** | {self.scan_results['framework']} |
| **Package Manager** | {self.scan_results['package_manager']} |
| **File Count** | {self.scan_results['file_structure']['file_count']} |
| **Directory Count** | {self.scan_results['file_structure']['dir_count']} |

---

## 📁 File Extensions

"""

        # Dosya uzantılarını tablo olarak ekle
        for ext, count in list(self.scan_results['file_structure']['extensions'].items())[:10]:
            context_content += f"- **{ext or 'no extension'}**: {count} dosya\n"

        context_content += f"""

---

## 🛠️ Tech Stack (Top 20)

"""

        # Tech stack'i ekle
        for i, tech in enumerate(self.scan_results['tech_stack'][:20], 1):
            context_content += f"{i}. {tech}\n"

        context_content += """

---

## 📝 Notes

This context is auto-generated by `scripts/scanner.py`. Please update it manually if needed.
"""

        # Dosyayı yaz
        output_path = self.project_root / output_file
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(context_content)

        print(f"\n✅ Context kaydedildi: {output_file}")

    def save_json(self, output_file: str = ".agent/state/scan-results.json"):
        """JSON formatında kaydet"""
        output_path = self.project_root / output_file
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(json.dumps(self.scan_results, indent=2, ensure_ascii=False))
        print(f"✅ JSON kaydedildi: {output_file}")


def main():
    """Ana fonksiyon"""
    import sys

    # Proje root tespit et
    if len(sys.argv) > 1:
        project_root = sys.argv[1]
    else:
        project_root = "."

    # Tara
    scanner = ProjectScanner(project_root)
    results = scanner.scan()

    # Kaydet
    scanner.save_context()
    scanner.save_json()

    print("\n🎉 Tarama tamamlandı!")


if __name__ == "__main__":
    main()
