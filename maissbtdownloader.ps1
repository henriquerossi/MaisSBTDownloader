# Baixar-Video-FFmpeg-Fix.ps1
# Versão corrigida: mostra saída do ffprobe e usa UTF-8 para acentuação

# chcp 65001

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Função para escrever títulos
function Write-Title {
    param([string]$Text)
    Clear-Host
    Write-Host ('━' * 81) -ForegroundColor White
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ('━' * 81) -ForegroundColor White
    Write-Host ''
}


# Pasta padrão de saída (Documentos do usuário)
$DocumentsPath = [Environment]::GetFolderPath('MyDocuments')

$ANO_ATUAL = (Get-Date).Year
$CopyrightChar = [char]0x00A9


# Variável de controle para o loop do menu
$MenuSelected = $false


# ===============================================
# INÍCIO DO MENU DE SELEÇÃO (Antes do while($true))
# ===============================================

do {
    Clear-Host
    Write-Host ('━' * 80) -ForegroundColor White
    Write-Host -NoNewline "                                 +SBT        " -ForegroundColor Cyan
    Write-Host "      $CopyrightChar $ANO_ATUAL" -ForegroundColor Yellow
    Write-Host ('━' * 80) -ForegroundColor White
    Write-Host ''
    Write-Host ''
    Write-Host "`t┏━━" -NoNewline
    Write-Host "Selecione uma opção" -ForegroundColor Yellow -NoNewline
    Write-Host "━━━━━━━━━━━━━━━┓"
    Write-Host "`t┃" -NoNewline
    Write-Host "1. Grade de programação +SBT Raiz" -ForegroundColor White -NoNewline
    Write-Host "   ┃"
    Write-Host "`t┃" -NoNewline
    Write-Host "2. Grade de programação +SBT Novelas" -ForegroundColor White -NoNewline
    Write-Host "┃"
    Write-Host "`t┃" -NoNewline
    Write-Host "3. Lista de programas On Demand" -ForegroundColor White -NoNewline
    Write-Host "     ┃"
    Write-Host "`t┃" -NoNewline
    Write-Host "4. +SBT Downloader" -ForegroundColor White -NoNewline
    Write-Host "                  ┃"
    Write-Host "`t┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"


    Write-Host ''
    $MenuChoice = Read-Host "`tOpção"

    switch ($MenuChoice) {
        "1" {
            # Opção: Grade de programação (Aviso para colar código)
            function Convert-TimestampToDateTime {
    param(
        [Parameter(Mandatory=$true)]
        [long]$TimestampInMs
    )

    [long]$EpochTicks = 621355968000000000
    [long]$Ticks = $TimestampInMs * 10000
    
    $DateTimeUtc = [datetime]::new($EpochTicks + $Ticks, [datetimekind]::Utc)
    
    return $DateTimeUtc.ToLocalTime()
}

function Get-ProgrammingSchedule {
    param(
        [Parameter(Mandatory=$true)]
        [string]$JsonUrl
    )

    try {
        # --- CORREÇÃO DE ENCODING PARA UTF-8 NO POWERSHELL 5.1 ---
        # 1. Usamos Invoke-WebRequest para obter o conteúdo RAW (bruto)
        $WebResponse = Invoke-WebRequest -Uri $JsonUrl -Method Get

        # 2. Acessamos o stream de conteúdo bruto e o convertemos para array de bytes
        $bytes = $WebResponse.RawContentStream.ToArray()

        # 3. Decodificamos o array de bytes usando explicitamente a codificação UTF-8
        $utf8 = [System.Text.Encoding]::UTF8
        $jsonString = $utf8.GetString($bytes)

        # 4. Convertemos a string decodificada (agora correta) em objeto PowerShell
        $RawData = $jsonString | ConvertFrom-Json
    }
    catch {
        Write-Error " Erro ao baixar ou analisar o JSON da URL: $($_.Exception.Message)"
        return $null
    }
    
    # Processa cada item do JSON (sem limitar o tamanho dos strings)
    $ProcessedData = $RawData | ForEach-Object {
        $DateTime = Convert-TimestampToDateTime -TimestampInMs $_.startTime

        [PSCustomObject]@{
            DateKey      = $DateTime.ToString("yyyy-MM-dd")
            DataHora     = $DateTime.ToString("dd/MM/yyyy HH:mm")
            HoraPura     = $DateTime.ToString("HH:mm")
            Title        = $_.title
            EpisodeName  = $_.episodeName
            MediaId      = $_.mediaId
            StartTimeMs  = $_.startTime
        }
    }

    $GroupedByDay = $ProcessedData | Group-Object -Property DateKey | Sort-Object Name

    return $GroupedByDay
}

function Save-AllScheduleToFile {
    param(
        [Parameter(Mandatory=$true)]
        [psobject[]]$GroupedData
    )

    $FileName = "Programacao_SBTRaiz_$(Get-Date -Format 'yyyyMMdd').txt"
    $FullPath = Join-Path -Path $DocumentsPath -ChildPath $FileName

    Write-Host "`nIniciando o salvamento da programação..." -ForegroundColor Cyan

    # Prepara o conteúdo, formatando cada dia
    $AllContent = $GroupedData | ForEach-Object {
        $ReadableDate = [datetime]::ParseExact($_.Name, "yyyy-MM-dd", [cultureinfo]::InvariantCulture).ToString("dddd, dd 'de' MMMM 'de' yyyy")

        # Cabeçalho do dia
        "========================================================================================="
        "     GRADE DE $ReadableDate  "
        "========================================================================================="
        
        # Conteúdo do dia formatado COMO TABELA
        # Usamos Format-Table e Out-String para garantir que a tabela seja salva corretamente
        $_.Group | Sort-Object StartTimeMs | Format-Table -Property @{
            Label = "Hora"; Expression = {$_.HoraPura}; Width = 10
        }, @{
            Label = "Título"; Expression = {$_.Title}; Width = 40
        }, @{
            Label = "Episódio/Detalhe"; Expression = {$_.EpisodeName}; Width = 40
        }, @{
            Label = "Media ID"; Expression = {$_.MediaId}; Width = 44
        } -Wrap | Out-String -Width 197 # Usamos uma largura grande (197) para prevenir quebras de linha indesejadas
        
        "`n" # Duas linhas extras para separar bem os dias
    }

    try {
        # Salva o conteúdo no arquivo, usando UTF8 para garantir caracteres especiais
        $AllContent | Out-File -FilePath $FullPath -Encoding UTF8
        Write-Host ''
        Write-Host 'Programação salva' -ForegroundColor Green
    }
    catch {
        Write-Error "Erro ao salvar o arquivo: $($_.Exception.Message)"
    }
    
    Write-Host "`n`n Pressione ENTER para voltar ao menu..." -ForegroundColor Magenta
    $null = Read-Host
}


function Select-Day {
    param(
        [Parameter(Mandatory=$true)]
        [psobject[]]$GroupedData
    )

    if (-not $GroupedData) {
        Write-Host "Não há dados para exibir."
        return $null
    }

    $DayOptions = @()
    $DayCounter = 1
    
    Clear-Host
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host "                                  PROGRAMAÇÃO +SBT RAIZ             " -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    
    # NOVA OPÇÃO DE SALVAR TUDO

    Write-Host "`n Dias de Programação Disponíveis:`n" -ForegroundColor Yellow

    foreach ($Group in $GroupedData) {
        $ReadableDate = [datetime]::ParseExact($Group.Name, "yyyy-MM-dd", [cultureinfo]::InvariantCulture).ToString("dddd, dd 'de' MMMM 'de' yyyy")
        
        Write-Host "`t$DayCounter. $ReadableDate"
        
        $DayOptions += [PSCustomObject]@{
            Index = $DayCounter
            DateKey = $Group.Name
        }
        $DayCounter++
    }

    [int]$SelectedNumber = 0 
    
    Write-Host "`nS - Salvar Programação Completa em TXT" -ForegroundColor Green
    Write-Host -NoNewline " (na pasta Documentos)" -ForegroundColor Yellow
    Write-Host ''
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    while ($true) {

        $Selection = Read-Host "Digite o número do dia, S para salvar a programação, ou Q para Sair"

        if ($Selection -ceq 'q') {
            return $null
        }

        # NOVO: Se o usuário digitar 's', retornamos um sinal especial
        if ($Selection -ceq 's') {
            return "SaveAll"
        }

        if ([int]::TryParse($Selection, [ref]$SelectedNumber)) {
            $SelectedDay = $DayOptions | Where-Object { $_.Index -eq $SelectedNumber }
            
            if ($SelectedDay) {
                return $SelectedDay.DateKey
            }
        }
        
        write-Host ''
        Write-Host "Entrada inválida. Por favor, digite um número válido, 'S' ou 'Q'." -ForegroundColor Red
    }
}

function Show-DaySchedule {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DateKey,
        [Parameter(Mandatory=$true)]
        [psobject[]]$GroupedData
    )
    
    Clear-Host

    $SelectedGroup = $GroupedData | Where-Object { $_.Name -eq $DateKey }

    if (-not $SelectedGroup) {
        Write-Host "Nenhum dado encontrado para a data $DateKey." -ForegroundColor Red
        return
    }

    $ReadableDate = [datetime]::ParseExact($DateKey, "yyyy-MM-dd", [cultureinfo]::InvariantCulture).ToString("dddd, dd 'de' MMMM 'de' yyyy")
    
    # Linhas de separação e título mais claros
    Write-Host ('━' * 97) -ForegroundColor Magenta
    Write-Host "                                        +SBT RAIZ" -ForegroundColor Cyan
    Write-Host ('━' * 97) -ForegroundColor Magenta
    Write-Host " Grade de $ReadableDate" -ForegroundColor Yellow
    Write-Host ('━' * 97) -ForegroundColor Magenta

    # Adicionado -Wrap para quebrar as linhas de texto longos e manter a formatação de tabela
    $SelectedGroup.Group | Sort-Object StartTimeMs | Format-Table -Property @{
        Label = "Hora"; Expression = {$_.HoraPura}; Width = 15
    }, @{
        Label = "Título"; Expression = {$_.Title}
    }, @{
        Label = "Episódio/Detalhe"; Expression = {$_.EpisodeName}
    }, @{
        Label = "Media ID"; Expression = {$_.MediaId}; Width = 65
    } -AutoSize -Wrap
    
    # Linha de separação final
    Write-Host ('━' * 97) -ForegroundColor Magenta
}

# ----------------------------------------
# PARTE PRINCIPAL DO SCRIPT
# ----------------------------------------

# ❗ SUBSTITUA ESTE LINK PELA SUA URL REAL DO JSON
$JsonLink = "https://bridge.evrideo.tv/SBTEPG?ChannelUID=raiz&DurationHours=168"

# 1. Obtém e Agrupa os dados
$ProgrammationData = Get-ProgrammingSchedule -JsonUrl $JsonLink

if ($ProgrammationData) {
    while ($true) {
        # 2. Lista os dias e obtém a seleção do usuário
        $Selection = Select-Day -GroupedData $ProgrammationData

        if (-not $Selection) {
            Write-Host "`nSaindo..." -ForegroundColor DarkGray
            break
        }

        # NOVO: Verifica se o usuário selecionou Salvar Tudo ('SaveAll' é o sinal)
        if ($Selection -ceq "SaveAll") {
            Save-AllScheduleToFile -GroupedData $ProgrammationData
            continue # Volta para o topo do loop (menu de seleção)
        }
        
        # 3. Exibe a programação para o dia selecionado
        Show-DaySchedule -DateKey $Selection -GroupedData $ProgrammationData

        Write-Host "`n Pressione ENTER para voltar ao menu de seleção de dias..." -ForegroundColor DarkGray
        $null = Read-Host
    }
}
        }
        "2" {
		& .\prognovelas.ps1 

            # Pausa para o usuário ver o resultado
            # Read-Host "Pressione Enter para voltar ao Menu"
	}
        "3" {
		& .\listapgm.ps1 

            # Pausa para o usuário ver o resultado
            # Read-Host "Pressione Enter para voltar ao Menu"
	}
        "4" {
            # Opção: Baixar vídeo (Downloader)

            # Define a variável para sair do loop 'do...while' do menu APÓS a conclusão do download
            # REMOVIDO: $MenuSelected = $true 
            
            
            # --- INÍCIO DO CÓDIGO DO +SBT DOWNLOADER (MOVIDO) ---
            
            while ($true) {

                Clear-Host
                Write-Host ('━' * 80) -ForegroundColor White
                Write-Host "                    +SBT DOWNLOADER            $CopyrightChar $ANO_ATUAL       " -ForegroundColor Cyan
                Write-Host ('━' * 80) -ForegroundColor White
                Write-Host ''
                Write-Host ''
                Write-Host ''
                Write-Host ''

                # 1. Solicita o Link do Vídeo
		Write-Host "┏━━" -NoNewline
		Write-Host "Digite o ID do vídeo" -NoNewline
		Write-Host " ou pressione ENTER para voltar ao menu inicial" -ForegroundColor Yellow -NoNewline
		Write-Host "━━━━━━━━━━┓"
		Write-Host "┃" -NoNewline
                $ID_VIDEO = Read-Host
                
                # O comando 'break' sai do loop 'while ($true)' e retorna ao menu principal (o loop 'do...while' externo).
                if ([string]::IsNullOrWhiteSpace($ID_VIDEO)) {
                    break
                }

                $LINK_VIDEO = "https://stream.maissbt.com/content/63/" + $ID_VIDEO + "/hls/master.m3u8"

                # Mostra informações com ffprobe (sem suprimir saída)
                Clear-Host
                Write-Title "                     ESCOLHER A QUALIDADE                   "
                Write-Host ''
                Write-Host "Aguarde..."


            # 2. Executa ffprobe e captura o JSON
            $FFProbeOutput = .\ffprobe -v quiet -print_format json -show_streams -show_programs -show_format $LINK_VIDEO | ConvertFrom-Json

            if (-not $FFProbeOutput) {
                Write-Error "Não foi possível obter dados do ffprobe."

                # Usa 'continue' para voltar ao topo do loop do Downloader (para nova ID)
                continue
            }

            # O JSON de saída agora só contém a seção 'streams' (e 'format'), onde 'program_id' está preenchido.
            if (-not $FFProbeOutput -or -not $FFProbeOutput.streams) {
                Write-Error "Não foi possível obter dados do ffprobe ou nenhum stream encontrado."
		
		# Adiciona a pausa e espera o usuário pressionar Enter
    		Read-Host "Pressione Enter para voltar" | Out-Null

                # Usa 'continue' para voltar ao topo do loop do Downloader (para nova ID)
                continue
            }

            # --- FUNÇÃO AUXILIAR PARA DURAÇÃO (NOVA) ---
            # Converte a duração de segundos (double) para HH:mm:ss
            function Format-Duration {
                param(
                    [Parameter(Mandatory=$true)]
                    [double]$TotalSeconds
                )
                # Cria um objeto TimeSpan a partir do total de segundos
                $TimeSpan = [System.TimeSpan]::FromSeconds($TotalSeconds)
                
                # Formata como HH:mm:ss (ou h:mm:ss se a hora for zero)
                # Usa 'g' para que omita as horas se for menos de 1 hora, mas 'hh\:mm\:ss' garante 00:xx:yy
                return $TimeSpan.ToString("hh\:mm\:ss")
            }


            # Função auxiliar para formatar o bitrate (de bits/s para kb/s)
            function Format-Bitrate {
                param(
                    [Parameter(Mandatory=$true)]
                    [long]$Bitrate
                )
                return [math]::Round(($Bitrate / 1000), 0)
            }

            # --- ETAPA 1: Mapear Program ID para Variant Bitrate (CORRIGIDO) ---

            # Cria um mapa: "VariantBitrate" -> "Program ID"
            $programIdMap = @{}
            if ($FFProbeOutput.programs) {
                # Itera sobre os programas (0, 1, 2, 3, 4...)
                $FFProbeOutput.programs | ForEach-Object {
                    
                    # Tenta extrair o Variant Bitrate da propriedade de Tags/Metadata
                    $bitrate = $null
                    
                    # Tentativa 1: Acessar tags diretamente (mais provável)
                    if ($_.tags -and $_.tags.variant_bitrate) {
                        $bitrate = $_.tags.variant_bitrate
                    }
                    # Tentativa 2: Acessar metadata (menos provável, mas seguro)
                    elseif ($_.metadata -and $_.metadata.variant_bitrate) {
                        $bitrate = $_.metadata.variant_bitrate
                    }
                    
                    # O program_id é o rótulo que queremos
                    $id = $_.program_id
                    
                    if ($bitrate -and $id -ne $null) {
                        # O ffprobe retorna o program_id como 0, 1, 2, 3, 4.
                        $programIdMap[$bitrate] = $id
                    }
                }
            }

            # --- O restante do script (ETAPA 2) permanece o mesmo ---
            # A Etapa 2 agora usará este $programIdMap corrigido para rotular os grupos.

            # --- ETAPA 2: Agrupar Streams pelo Variant Bitrate ---

            # Agrupa os streams pela tag 'variant_bitrate' (o que funcionou para separar os grupos)
            $streamsAgrupados = $FFProbeOutput.streams | Group-Object { $_.tags.variant_bitrate } | Sort-Object Name

            # --- CÁLCULO E EXIBIÇÃO DA DURAÇÃO (NOVA) ---

            $duracaoSegundos = $null
            $duracaoFormatada = "N/A"

            if ($FFProbeOutput.format -and $FFProbeOutput.format.duration) {
                # O valor da duração é uma string, converte para double antes de formatar
                $duracaoSegundos = [double]$FFProbeOutput.format.duration
                $duracaoFormatada = Format-Duration $duracaoSegundos
            }


                Clear-Host
                Write-Title "                     ESCOLHER A QUALIDADE                   "


                Write-Host "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
                Write-Host "┃" -NoNewline
                Write-Host "Duração: " -NoNewline -ForegroundColor White
                Write-Host "$duracaoFormatada" -ForegroundColor Yellow -NoNewline
                Write-Host "                                                              ┃"
                Write-Host "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"





            # Itera sobre cada grupo
            foreach ($grupo in $streamsAgrupados) {
                
                $bitrateVariant = $grupo.Name
                
                # Busca o ID original (0, 1, 2, 3, 4) no mapa criado
                $programIdDisplay = if ($programIdMap.ContainsKey($bitrateVariant)) {
                    $programIdMap[$bitrateVariant]
                } else {
                    "N/A (Não Mapeado)"
                }

                $bitrateKbs = if ($bitrateVariant) { Format-Bitrate $bitrateVariant } else { 'N/A' }

                # Encontra o stream de VÍDEO dentro do grupo atual
                $videoStream = $grupo.Group | Where-Object { $_.codec_type -eq "video" } | Select-Object -First 1
                
                $resolucaoCabecalho = ""
                if ($videoStream -and $videoStream.height) {
                    # Formata a altura (ex: 720p)
                    $resolucaoCabecalho = "$($videoStream.height)p"
                } else {
                    $resolucaoCabecalho = "N/A"
                }
                

                Write-Host "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                Write-Host "┃" -NoNewline
                Write-Host -NoNewline "PROGRAM ID: " -ForegroundColor Magenta
                Write-Host -NoNewline "$programIdDisplay" -ForegroundColor Yellow
                
                # 3. Adiciona a Resolução ao lado do ID (destacada)
                if ($resolucaoCabecalho -ne "N/A") {
                    Write-Host "                                                             $resolucaoCabecalho" -ForegroundColor Green
                } 
                Write-Host "┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

                # Itera sobre os streams dentro deste programa
                foreach ($stream in $grupo.Group) {
                    $indiceStream = $stream.index
                    $tipoCodec = $stream.codec_type
                    $nomeCodec = $stream.codec_name
                    
                    
                    # 2. Obtém o bitrate (se existir)
                    # NOTA: O $stream.bit_rate é o 'bitrate' (não o 'variant_bitrate' na tag)
                    $bitrateStreamKbs = if ($stream.bit_rate) { Format-Bitrate $stream.bit_rate } else { 'N/A' }
                    
                    # 3. Obtém o Variant Bitrate do stream
                    $variantBitrateValue = if ($stream.tags -and $stream.tags.variant_bitrate) { $stream.tags.variant_bitrate } else { $null }
                    $variantBitrateTag = if ($variantBitrateValue) { Format-Bitrate $variantBitrateValue } else { 'N/A' }


                    # Constrói a linha de saída base
                    Write-Host "┃" -NoNewline
                    $linhaSaida = "[Stream #$indiceStream - $($tipoCodec.ToUpper())] $nomeCodec"

                    # Adiciona informações específicas do tipo de stream
                    switch ($tipoCodec) {
                        "video" {
                            $resolucao = "$($stream.width)x$($stream.height)" 
                            $linhaSaida += " | Resolução: $resolucao"
                            
                            # --- LÓGICA DE FALLBACK APLICADA AQUI ---
                            $bitrateDisplay = $bitrateStreamKbs
                            
                            function Format-BitrateMb {
                                param(
                                    [Parameter(Mandatory=$true)]
                                    # Define como [double] para aceitar strings e garantir a precisão
                                    [double]$variantBitrateValue
                                )
                                # Divide o valor (agora tratado como double) por 1.000.000 e arredonda para 2 casas
                                return [math]::Truncate(($variantBitrateValue / 1000000) * 100) / 100
                            }

                            if ($bitrateDisplay -eq 'N/A' -and $variantBitrateValue) {
                                # Se o bitrate do stream (N/A) estiver faltando, usa o Variant Bitrate como fallback.
                                $bitrateDisplay = (Format-Bitrate $variantBitrateValue)
                                $bitrateMbC = (Format-BitrateMb $variantBitrateValue)
                            }
                            $linhaSaida += " | Bitrate: {0:N2} Mb/s" -f $bitrateMbC
                            # ----------------------------------------
                        }
                        "audio" {
                            $canais = if ($stream.channels) { $stream.channels } else { 'N/A' }
                            $linhaSaida += " | $canais canais"
                            $linhaSaida += " | Bitrate: $bitrateStreamKbs kb/s" # Áudio usa o bitrate do stream.
                        }

                    }
                    
                    # Mantemos a tag Variant Bitrate separada para clareza
                    # $linhaSaida += " | Variant Bitrate: $variantBitrateTag kb/s"


                    Write-Host $linhaSaida
                }

                Write-Host "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                Write-Host ''

            }

                # Escolher qualidade (ID numérico)
                do { 
		    Write-Host "Digite o número do ID" -NoNewline
		    Write-Host " (ou pressione ENTER para voltar): " -NoNewline -ForegroundColor Yellow
                    $ESCOLHA_QUALIDADE = Read-Host
        
        # --- NOVO: Verifica se o usuário pressionou ENTER para voltar ---
        if ([string]::IsNullOrWhiteSpace($ESCOLHA_QUALIDADE)) {
            # Define $validQual como 'true' para sair do loop 'do...while' interno
            $validQual = $true
            # Define uma flag para indicar que deve-se voltar ao loop de ID do vídeo
            $VoltarAoMenuID = $true
            break
        }
        # -----------------------------------------------------------------
        
        else {
            if ($ESCOLHA_QUALIDADE -match '^\d+$') {
                $validQual = $true
            }
            else {
                Write-Host "Opção inválida. Tente novamente." -ForegroundColor Red
                Start-Sleep -Seconds 2
                $validQual = $false
            }
        }
    } while (-not $validQual)

    # Verifica a flag de retorno
    if ($VoltarAoMenuID) {
        continue # Volta para o loop while ($true) principal, que solicita o ID do vídeo
    }

                Clear-Host
                Write-Host ''
                Write-Host ('━' * 80)
                Write-Host "                                  NOMEAR ARQUIVO                " -ForegroundColor Yellow
                Write-Host ('━' * 80)
                Write-Host ''

                $NOME_PROGRAMA = Read-Host "   Digite o nome do programa"

                Write-Host ''
                Write-Host ''

                $NUM_EP = Read-Host "   Digite o número do episódio"

                Write-Host ''
                Write-Host ''
                Write-Host ''

                $NOME_ARQUIVO = "$NOME_PROGRAMA - $NUM_EP.mp4"


                Write-Host ('━' * 80) -ForegroundColor White
                Write-Host ''
                Write-Host "    Nome final: " -NoNewline; Write-Host $NOME_ARQUIVO -ForegroundColor Magenta
                Write-Host ''
                Write-Host ('━' * 80) -ForegroundColor White
                Write-Host ''
                Write-Host ''
                Write-Host ''
                Write-Host "     Pressione ENTER para continuar..." -ForegroundColor Yellow
                $null = Read-Host


                # INICIAR DOWNLOAD
                Clear-Host
                Write-Host ''
                Write-Host ('━' * 80) -ForegroundColor White
                Write-Host "                    INICIANDO O DOWNLOAD                       " -ForegroundColor Cyan
                Write-Host ('━' * 80) -ForegroundColor White
                Write-Host ''

                # Comando ffmpeg
                $OutputPath = Join-Path -Path $DocumentsPath -ChildPath $NOME_ARQUIVO
                $MapOption = "0:p:$ESCOLHA_QUALIDADE"

                try {
                    .\ffmpeg -user_agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36" -i $LINK_VIDEO -hide_banner -map $MapOption -sn -c:v copy -c:a copy $OutputPath 
                } catch {
                    Write-Host "Erro ao executar ffmpeg. Verifique se ffmpeg está instalado e no PATH." -ForegroundColor Red
                }

                Write-Host ''
                Write-Host ''
                Write-Host ''
                Write-Host ''
                Write-Host ('━' * 80) -ForegroundColor White
                Write-Host ''
                Write-Host "                      DOWNLOAD CONCLUÍDO!                      " -ForegroundColor Green
                Write-Host ''
                Write-Host ('━' * 80) -ForegroundColor White
                Write-Host ''
                Write-Host "Pressione Enter para baixar outro vídeo..."
                Read-Host | Out-Null
            }
            
            # --- FIM DO CÓDIGO DO +SBT DOWNLOADER (MOVIDO) ---
            
        }
        default {
            Write-Host "Opção inválida. Por favor, digite 1, 2 ou 3." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($true) # O loop agora é 'while ($true)' pois a Opção 3 contém seu próprio 'break' para voltar.