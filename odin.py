#!/usr/bin/env python3
"""
ODIN AI Agent System - Unified CLI
Multi-agent orchestration için komuta merkezi.

Version: 1.0.0
Usage: odin <command> [options]
"""

import json
import uuid
from datetime import datetime
from pathlib import Path
from typing import Optional, List

import typer
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.prompt import Prompt, Confirm
from rich import print as rprint

# CLI app
app = typer.Typer(
    name="odin",
    help="🪦 ODIN AI Agent System - Multi-Agent Orchestration CLI",
    no_args_is_help=True,
)

# Console
console = Console()

# Paths
PROJECT_ROOT = Path(__file__).parent.resolve()
STATE_DIR = PROJECT_ROOT / ".agent" / "state"
QUEUE_DIR = PROJECT_ROOT / ".agent" / "queue"
LIBRARY_DIR = PROJECT_ROOT / ".agent" / "library"

# Agent types with circuits
AGENT_TYPES = [
    "orchestrator", "planner", "analyst",
    "frontend", "backend", "mobile", "database", "api-design", "security", "performance", "architect",
    "researcher", "competitive", "documentation", "config",
    "reviewer-code", "reviewer-security", "reviewer-performance", "reviewer-business", "reviewer-ui",
    "testing", "fixer", "deps", "build", "debugger",
]


def get_queue_file(status: str) -> Path:
    """Queue dosyasını al"""
    return QUEUE_DIR / f"tasks-{status}.json"


def load_queue(status: str) -> List[dict]:
    """Queue dosyasını oku"""
    queue_file = get_queue_file(status)
    if queue_file.exists():
        data = json.loads(queue_file.read_text(encoding="utf-8"))
        # Queue yapısını kontrol et: {"tasks": [], "metadata": {}} veya []
        if isinstance(data, dict) and "tasks" in data:
            return data.get("tasks", [])
        return data if isinstance(data, list) else []
    return []


def save_queue(status: str, tasks: List[dict]) -> None:
    """Queue dosyasını yaz"""
    queue_file = get_queue_file(status)
    queue_file.parent.mkdir(parents=True, exist_ok=True)

    # Dosya var mı kontrol et
    if queue_file.exists():
        data = json.loads(queue_file.read_text(encoding="utf-8"))
        # Mevcut yapıyı koru
        if isinstance(data, dict) and "metadata" in data:
            data["tasks"] = tasks
            data["lastUpdated"] = datetime.now().isoformat()
            queue_file.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
            return

    # Yeni dosya: mevcut formatı kullan
    from datetime import timezone
    new_data = {
        "tasks": tasks,
        "metadata": {
            "version": "1.0.0",
            "lastUpdated": datetime.now(timezone.utc).isoformat(),
            "description": f"Tasks in {status} status"
        }
    }
    queue_file.write_text(json.dumps(new_data, indent=2, ensure_ascii=False), encoding="utf-8")


def check_circuit(agent_type: str) -> str:
    """Circuit breaker durumunu kontrol et"""
    circuits_file = STATE_DIR / "circuits.json"
    if circuits_file.exists():
        circuits = json.loads(circuits_file.read_text(encoding="utf-8"))
        circuit = circuits.get("circuits", {}).get(agent_type, {})
        return circuit.get("state", "CLOSED")
    return "CLOSED"


@app.command()
def add(
    task: str = typer.Argument(..., help="Görev tanımı"),
    agent: Optional[str] = typer.Option(None, "--agent", "-a", help="Agent tipi"),
    priority: Optional[str] = typer.Option("normal", "--priority", "-p", help="Öncelik (low, normal, high, critical)"),
    tags: Optional[str] = typer.Option(None, "--tags", "-t", help="Etiketler (virgülle ayrılmış)"),
):
    """
    Yeni görev ekle.

    Example:
        odin add "User authentication system oluştur" --agent backend --priority high
    """
    # Agent validate et
    if agent and agent not in AGENT_TYPES:
        console.print(f"[red]❌ Geçersiz agent tipi: {agent}[/red]")
        console.print(f"[yellow]Geçerli agent'lar: {', '.join(AGENT_TYPES)}[/yellow]")
        raise typer.Exit(1)

    # Circuit kontrolü
    if agent:
        circuit_state = check_circuit(agent)
        if circuit_state == "OPEN":
            console.print(f"[red]🔴 Circuit OPEN: {agent} agent bloke[/red]")
            if not Confirm.ask("Yine de eklemek istiyor musunuz?"):
                raise typer.Exit(0)

    # Task oluştur
    task_id = str(uuid.uuid4())[:8]
    new_task = {
        "id": task_id,
        "description": task,
        "agent": agent or "auto",
        "priority": priority,
        "tags": [t.strip() for t in tags.split(",")] if tags else [],
        "status": "pending",
        "created_at": datetime.now().isoformat(),
        "retry_count": 0,
        "dependencies": [],
    }

    # Queue'ya ekle
    pending_tasks = load_queue("pending")
    pending_tasks.append(new_task)
    save_queue("pending", pending_tasks)

    # Çıktı
    console.print(Panel.fit(
        f"[green]✅ Görev eklendi[/green]\n\n"
        f"[cyan]ID:[/cyan] {task_id}\n"
        f"[cyan]Görev:[/cyan] {task}\n"
        f"[cyan]Agent:[/cyan] {agent or 'auto'}\n"
        f"[cyan]Öncelik:[/cyan] {priority}",
        title="📋 Yeni Görev",
        border_style="green"
    ))


@app.command()
def list(
    status: Optional[str] = typer.Option("pending", "--status", "-s", help="Queue durumu (pending, in-progress, completed, failed, dead-letter)"),
):
    """
    Queue listele.

    Example:
        odin list --status pending
        odin list -s in-progress
    """
    valid_statuses = ["pending", "in-progress", "completed", "failed", "dead-letter"]
    if status not in valid_statuses:
        console.print(f"[red]❌ Geçersiz durum: {status}[/red]")
        console.print(f"[yellow]Geçerli durumlar: {', '.join(valid_statuses)}[/yellow]")
        raise typer.Exit(1)

    tasks = load_queue(status)

    if not tasks:
        console.print(f"[yellow]⚠️  {status} queue'si boş[/yellow]")
        return

    # Tablo oluştur
    table = Table(title=f"📋 Queue: {status}")
    table.add_column("ID", style="cyan", width=8)
    table.add_column("Görev", style="white", width=50)
    table.add_column("Agent", style="blue", width=15)
    table.add_column("Öncelik", style="yellow", width=10)
    table.add_column("Tarih", style="dim", width=20)

    for task in tasks:
        priority_style = {
            "critical": "[red]CRITICAL[/red]",
            "high": "[orange]HIGH[/orange]",
            "normal": "[white]NORMAL[/white]",
            "low": "[dim]LOW[/dim]",
        }.get(task["priority"], task["priority"])

        table.add_row(
            task["id"],
            task["description"][:47] + "..." if len(task["description"]) > 50 else task["description"],
            task["agent"],
            priority_style,
            task["created_at"][:19],
        )

    console.print(table)
    console.print(f"\n[dim]Toplam: {len(tasks)} görev[/dim]")


@app.command()
def kick(
    task_id: Optional[str] = typer.Argument(None, help="Görev ID (boş bırakılırsa ilk pending görev)"),
):
    """
    Görevi başlat (queue'dan agent'e gönder).

    Example:
        odin kick           # İlk pending görevi başlat
        odin kick abc123    # Spesifik görevi başlat
    """
    pending_tasks = load_queue("pending")

    if not pending_tasks:
        console.print("[yellow]⚠️  Bekleyen görev yok[/yellow]")
        return

    # Task seç
    if task_id:
        # ID'ye göre bul
        task_to_kick = None
        for i, task in enumerate(pending_tasks):
            if task["id"] == task_id:
                task_to_kick = task
                index = i
                break

        if not task_to_kick:
            console.print(f"[red]❌ Görev bulunamadı: {task_id}[/red]")
            raise typer.Exit(1)
    else:
        # İlk görev
        task_to_kick = pending_tasks[0]
        index = 0

    # Circuit kontrolü
    agent = task_to_kick.get("agent")
    if agent and agent != "auto":
        circuit_state = check_circuit(agent)
        if circuit_state == "OPEN":
            console.print(f"[red]🔴 Circuit OPEN: {agent} agent bloke[/red]")
            console.print(f"[yellow]💡 Alternatif: 'odin kick {pending_tasks[1]['id']}' ile diğer görevi dene[/yellow]")
            raise typer.Exit(1)

    # Task'ı pending'den sil, in-progress'e ekle
    pending_tasks.pop(index)
    save_queue("pending", pending_tasks)

    task_to_kick["status"] = "in-progress"
    task_to_kick["started_at"] = datetime.now().isoformat()

    in_progress_tasks = load_queue("in-progress")
    in_progress_tasks.append(task_to_kick)
    save_queue("in-progress", in_progress_tasks)

    # Çıktı
    console.print(Panel.fit(
        f"[green]🚀 Görev başlatıldı[/green]\n\n"
        f"[cyan]ID:[/cyan] {task_to_kick['id']}\n"
        f"[cyan]Görev:[/cyan] {task_to_kick['description']}\n"
        f"[cyan]Agent:[/cyan] {agent or 'auto'}\n"
        f"[cyan]Öncelik:[/cyan] {task_to_kick['priority']}\n\n"
        f"[dim]💡 Agent'in görevi tamamlamasını bekleyin veya 'odin list --status in-progress' ile takip edin[/dim]",
        title="⚡ Görev Başlatıldı",
        border_style="green"
    ))


@app.command()
def status():
    """Tüm queue durumlarını göster"""
    console.print("\n[bold cyan]📊 Queue Durumları[/bold cyan]\n")

    statuses = ["pending", "in-progress", "completed", "failed", "dead-letter"]
    total = 0

    for stat in statuses:
        tasks = load_queue(stat)
        count = len(tasks)
        total += count

        # Renkler
        color = {
            "pending": "yellow",
            "in-progress": "blue",
            "completed": "green",
            "failed": "red",
            "dead-letter": "red",
        }.get(stat, "white")

        # Bar
        bar_length = min(count * 2, 40)
        bar = "█" * bar_length

        console.print(f"  [{color}]{stat:15}[/{color}] [{color}]{bar}[/{color}] [white]{count:3}[/white]")

    console.print(f"\n  [dim]{'─' * 65}[/dim]")
    console.print(f"  [bold]{'TOPLAM':15}[/bold] [white]{total:46}[/white]\n")


@app.command()
def scan():
    """Proje tara ve context güncelle"""
    import subprocess

    console.print("[cyan]🔍 Proje taranıyor...[/cyan]")

    result = subprocess.run(
        ["python", ".agent/scripts/scanner.py"],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True
    )

    if result.returncode == 0:
        console.print("[green]✅ Tarama tamamlandı[/green]")
        console.print(result.stdout)
    else:
        console.print("[red]❌ Tarama başarısız[/red]")
        console.print(result.stderr)
        raise typer.Exit(1)


@app.command()
def context():
    """Context dosyasını göster"""
    context_file = PROJECT_ROOT / ".agent" / "context.md"

    if not context_file.exists():
        console.print("[yellow]⚠️  Context dosyası yok[/yellow]")
        console.print("[dim]💡 'odin scan' ile context oluştur[/dim]")
        return

    console.print(context_file.read_text(encoding="utf-8"))


@app.command()
def memory():
    """Memory dosyasını göster"""
    memory_file = STATE_DIR / "memory.md"

    if not memory_file.exists():
        console.print("[yellow]⚠️  Memory dosyası yok[/yellow]")
        return

    console.print(memory_file.read_text(encoding="utf-8"))


@app.command()
def active():
    """Active context dosyasını göster"""
    active_file = STATE_DIR / "active_context.md"

    if not active_file.exists():
        console.print("[yellow]⚠️  Active context dosyası yok[/yellow]")
        return

    console.print(active_file.read_text(encoding="utf-8"))


@app.command()
def agents():
    """Tüm agent tiplerini listele"""
    console.print("\n[bold cyan]🤖 Agent Tipleri[/bold cyan]\n")

    # Kategorilere göre分组
    categories = {
        "Core": ["orchestrator", "planner", "analyst"],
        "Development": ["frontend", "backend", "mobile", "database", "api-design", "security", "performance", "architect"],
        "Research": ["researcher", "competitive", "documentation", "config"],
        "Quality": ["reviewer-code", "reviewer-security", "reviewer-performance", "reviewer-business", "reviewer-ui"],
        "Support": ["testing", "fixer", "deps", "build", "debugger"],
    }

    for category, agents in categories.items():
        console.print(f"  [bold yellow]{category}[/bold yellow]")
        for agent in agents:
            circuit_state = check_circuit(agent)
            circuit_icon = {
                "CLOSED": "[green]✓[/green]",
                "OPEN": "[red]✗[/red]",
                "HALF_OPEN": "[yellow]~[/yellow]",
            }.get(circuit_state, "?")

            console.print(f"    {circuit_icon} [dim]{agent}[/dim]")
        console.print()


@app.command()
def update():
    """Active context ve memory dosyalarını güncelle"""
    import subprocess

    console.print("[cyan]🔄 Context güncelleniyor...[/cyan]\n")

    # 1. Scanner çalıştır
    console.print("[dim]1. Proje taranıyor...[/dim]")
    result = subprocess.run(
        ["python", ".agent/scripts/scanner.py"],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        console.print("[red]❌ Scanner başarısız[/red]")
        console.print(result.stderr)
        return

    # 2. Queue durumlarını al
    console.print("[dim]2. Queue durumları alınıyor...[/dim]")
    statuses = ["pending", "in-progress", "completed", "failed", "dead-letter"]
    queue_summary = {}
    for stat in statuses:
        tasks = load_queue(stat)
        queue_summary[stat] = len(tasks)

    # 3. Active context güncelle
    console.print("[dim]3. Active context güncelleniyor...[/dim]")
    active_file = STATE_DIR / "active_context.md"

    # Mevcut içeriği oku
    if active_file.exists():
        content = active_file.read_text(encoding="utf-8")
    else:
        content = "# Active Context - Canlı Hafıza\n\n"

    # Tarih ve saat güncelle
    now = datetime.now()
    timestamp = now.strftime("%Y-%m-%d %H:%M")

    # Güncel durum
    total_tasks = sum(queue_summary.values())

    new_content = f"""# Active Context - Canlı Hafıza

> **Son Güncelleme:** {timestamp}
> **Otomatik güncelleme** - `odin update`

---

## 📍 Şu Anki Durum

### Queue Özeti
| Durum | Görev Sayısı |
|-------|-------------|
| Pending | {queue_summary['pending']} |
| In-Progress | {queue_summary['in-progress']} |
| Completed | {queue_summary['completed']} |
| Failed | {queue_summary['failed']} |
| Dead-Letter | {queue_summary['dead-letter']} |
| **TOPLAM** | **{total_tasks}** |

---

## 🔴 Hızlı Erişim

### CLI Komutları
```bash
# Durum görüntüle
python odin.py status

# Görev ekle
python odin.py add "Görev tanımı" --agent <agent>

# Queue listele
python odin.py list

# Context görüntüle
python odin.py context
python odin.py memory
python odin.py active
```

### Proje Bilgileri
- **Proje:** ODIN AI Agent System v1.0.0
- **Scanner:** Son tarama {timestamp}
- **Toplam Görev:** {total_tasks}
- **Agent Sayısı:** 25 specialized agent

---

**Bu dosya `odin update` komutu ile otomatik güncellenir.**
"""

    active_file.parent.mkdir(parents=True, exist_ok=True)
    active_file.write_text(new_content, encoding="utf-8")

    console.print("[green]✅ Active context güncellendi[/green]\n")

    # 4. Özet göster
    console.print(Panel.fit(
        f"[green]✅ Güncelleme tamamlandı[/green]\n\n"
        f"[cyan]Timestamp:[/cyan] {timestamp}\n"
        f"[cyan]Toplam Görev:[/cyan] {total_tasks}\n\n"
        f"[dim]💡 'odin status' ile detaylı durum görüntüle[/dim]",
        title="🔄 Güncelleme Tamam",
        border_style="green"
    ))


@app.command()
def version():
    """Versiyon bilgisi"""
    console.print(Panel.fit(
        "[bold cyan]🪦 ODIN AI Agent System[/bold cyan]\n\n"
        "[dim]Version:[/dim] [white]1.0.0[/white]\n"
        "[dim]Author:[/dim] [white]ODIN Development Team[/white]\n"
        "[dim]License:[/dim] [white]MIT[/white]",
        border_style="cyan"
    ))


if __name__ == "__main__":
    app()
