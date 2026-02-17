#!/bin/bash

# ==========================================
# Server Monitoring Report Script
# Author: Cesar
# Description: Generates HTML server reports
# ==========================================

set -euo pipefail

# ===== VARIABLES GLOBALES =====
REPORT_DIR="$HOME/server_reports"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_FILE="$REPORT_DIR/report_$TIMESTAMP.html"
SCAN_DIR="/home"


# ===== CREAR DIRECTORIO SI NO EXISTE =====
mkdir -p "$REPORT_DIR"
# ===== FUNCION: INFORMACION GENERAL =====
get_system_info() {
    HOSTNAME=$(hostname)
    UPTIME=$(uptime -p)
    KERNEL=$(uname -r)
    IP=$(hostname -I | awk '{print $1}')
    LOAD=$(uptime | awk -F'load average:' '{print $2}')

    echo "
    <h2>Información General</h2>
    <ul>
        <li><strong>Hostname:</strong> $HOSTNAME</li>
        <li><strong>IP:</strong> $IP</li>
        <li><strong>Kernel:</strong> $KERNEL</li>
        <li><strong>Uptime:</strong> $UPTIME</li>
        <li><strong>Load Average:</strong> $LOAD</li>
    </ul>
    "
}

# ===== FUNCION: METRICAS DEL SISTEMA =====
get_performance_metrics() {

    CPU_LOAD=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
    RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
    RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    DISK_USED=$(df -h / | awk 'NR==2 {print $5}')

    echo "
    <h2>Métricas de Rendimiento</h2>
    <ul>
        <li><strong>Uso de CPU:</strong> ${CPU_LOAD}%</li>
        <li><strong>RAM usada:</strong> ${RAM_USED}MB / ${RAM_TOTAL}MB</li>
        <li><strong>Uso de Disco (/):</strong> ${DISK_USED}</li>
    </ul>
    "
}



# ===== FUNCION: TOP 10 ARCHIVOS MAS GRANDES =====
get_top_files() {

    echo "<h2>Top 10 Archivos Más Grandes en $SCAN_DIR</h2>"
    echo "<pre>"

    find "$SCAN_DIR" -type f -exec du -h {} + 2>/dev/null \
        | sort -hr \
        | head -n 10

    echo "</pre>"
}

## ===== FUNCION: TOP 10 PROCESOS POR CPU =====
get_top_processes() {

    echo "<h2>Top 10 Procesos con Mayor Uso de CPU</h2>"
    echo "<table>"
    echo "<tr>
            <th>PID</th>
            <th>Proceso</th>
            <th>CPU %</th>
            <th>MEM %</th>
          </tr>"

    ps -eo pid,comm,%cpu,%mem --sort=-%cpu \
        | head -n 11 \
        | tail -n +2 \
        | while read pid comm cpu mem; do
            echo "<tr>
                    <td>$pid</td>
                    <td>$comm</td>
                    <td>$cpu</td>
                    <td>$mem</td>
                  </tr>"
        done

    echo "</table>"
}

# ===== GENERAR REPORTE =====

{
echo "<html>"
echo "<head>
<title>Server Report</title>
<style>
body { font-family: Arial; background-color: #f4f4f4; padding: 20px; }
h1 { color: #2c3e50; }
h2 { color: #34495e; }
ul { background: white; padding: 15px; border-radius: 8px; }
li { margin: 8px 0; }

table {
  width: 100%;
  border-collapse: collapse;
  background: white;
  border-radius: 8px;
  overflow: hidden;
}

th, td {
  padding: 10px;
  border-bottom: 1px solid #ddd;
  text-align: left;
}

th {
  background-color: #2c3e50;
  color: white;
}

tr:hover {
  background-color: #f1f1f1;
}
</style>
</head>"
echo "<body>"
echo "<h1>Reporte del Servidor</h1>"
echo "<p><strong>Fecha:</strong> $TIMESTAMP</p>"

get_system_info
get_performance_metrics
get_top_files
get_top_processes

echo "</body>"
echo "</html>"
} > "$REPORT_FILE"

push_to_git() {
    cd "$REPORT_DIR" || exit 1

    git add .
    git commit -m "Reporte automático $TIMESTAMP" || true
    git push origin main
}
push_to_git