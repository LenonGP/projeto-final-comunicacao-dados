# Modem acústico — UFSM00050 Comunicação de Dados (2026/2)

Equipe: João Pedro Souto, Lenon Gabriel Paranhos, Ryan dos Santos.
Multiplexação escolhida: **TDM síncrono** com dois fluxos (A = "OLA", B = "UFS").
Testado no MATLAB R2025b (toolboxes Signal Processing e Communications, usadas pelo modem fornecido).
No GNU Octave, os pacotes `signal` e `communications` precisam estar instalados (o modem já faz `pkg load`).

## Pontos de entrada

| Lado | Função | O que faz |
|---|---|---|
| Transmissor | `funcoes/cadeia_tx.m` | fluxo → CRC-8 → Hamming(7,4) → TDM (bits) |
| | `funcoes/modem_tx_bits.m` | bits → sinal BPSK (usa o `transmissor.m` fornecido) |
| Receptor | `funcoes/modem_rx_bits.m` | sinal → bits (pré-processamento + `receptor_3.m`) |
| | `funcoes/cadeia_rx.m` | bits → demux TDM → Hamming → verificação CRC |

Todos os parâmetros ficam em `funcoes/config_modem.m` (taxa, portadora, mensagens, polinômio, quadro TDM).

## Como reproduzir os testes

Abra o MATLAB na pasta do projeto e rode cada script de `testes/`. Cada um grava
um log `.txt` (e figuras, quando houver) em `resultados/`.

| Script | Teste | Tipo |
|---|---|---|
| `testes/T1_enlace_basico.m` | enlace básico, 10 rodadas, com e sem pré-processamento | **acústico** |
| `testes/T2_deteccao_crc.m` | CRC-8: 1 bit, 2 bits, rajadas de 2 a 8 bits | software |
| `testes/T3_correcao_hamming.m` | Hamming(7,4): 1 e 2 erros por palavra, limite do código | software |
| `testes/T4_multiplexacao_tdm.m` | TDM isolado, com bits de lixo antes do 1º quadro | software |
| `testes/T5_integrado_software.m` | CRC + Hamming + TDM com erros injetados | software |
| `testes/T6_integrado_modem.m` | sistema integrado pelo modem, 10 rodadas | **acústico** ou simulação |
| `testes/comparacao_receptores.m` | `receptor_2` (original) × `receptor_3` | simulação + gravações |
| `testes/figuras_relatorio.m` | figuras ilustrativas do relatório (espectro, demodulação, pré-processamento, erros do T5) | usa as gravações salvas |

O T1 e o T6 têm a variável `modo` no topo do script:
- `'acustico'`: toca no alto-falante e grava no microfone, salvando as gravações em `sinal/`;
- `'simulacao'` (só no T6): o sinal vai direto ao receptor, com ruído opcional (`snr_db`);
- `'arquivo'`: decodifica de novo as gravações já salvas.

Para o teste acústico, deixe o microfone perto do alto-falante, com o volume alto e a sala em silêncio.

## Estrutura do quadro

- **TDM** (8 quadros, 176 bits): `[SYNC 01111110 | slot A (7 bits) | slot B (7 bits)]`.
  Cada slot leva uma palavra Hamming de cada fluxo.
- **Por fluxo**: 24 bits de dados + 8 de CRC = 32 bits, que viram 56 bits com o Hamming(7,4).
- **Modem**: os 176 bits viram 22 bytes, enviados como dados no quadro `PRE | SFD | tamanho | dados | PRE` do transmissor fornecido.

## Arquivos do modem

- `transmissor.m`, `rcosine.m`, `rcosflt.m`, `receptor_0/1/2.m`: fornecidos na disciplina, sem alteração.
- `receptor_3.m`: cópia do `receptor_2.m` com um filtro passa-baixas depois da demodulação.
  Sem esse filtro, a componente em 2·Fp (4 kHz = Fa/2) faz a decisão depender da
  posição da amostra (ver `testes/comparacao_receptores.m`).
- `tx_enlace.m`, `rx_enlace.m`, `enlace_loopback.m`: scripts do Marco 2 (usam o `receptor_2`).
