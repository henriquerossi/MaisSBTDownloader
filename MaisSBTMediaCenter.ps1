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


function Escrever-Divisor {
    param(
        # Aqui definimos o caractere PADRÃO. Se você não digitar nada, ele usa este:
        [string]$Char = '━', 
        
        # Aqui definimos a COR PADRÃO:
        [string]$Cor = 'Magenta'
    )

    # Captura a largura da janela e subtrai 1 para não quebrar a linha
    $L = $Host.UI.RawUI.WindowSize.Width - 1

    # Faz a mágica: repete o caractere escolhido pela largura da janela
    Write-Host ($Char * $L) -ForegroundColor $Cor
}


function Escrever-Centro {
    param([string]$Texto, [string]$Cor = "White")
    $L = $Host.UI.RawUI.WindowSize.Width - 1
    $pos = [math]::Floor(($L + $Texto.Length) / 2)
    Write-Host $Texto.PadLeft($pos) -ForegroundColor $Cor
}


function Escrever-CabecalhoSBT {
    # Definimos os textos e cores aqui dentro para facilitar
    $txt1 = "+SBT Media Center "
    $cor1 = "Cyan"
    $txt2 = "$CopyrightChar $ANO_ATUAL"
    $cor2 = "Magenta"

    # Calculamos a largura total e o recuo (padding)
    $larguraTotal = $txt1.Length + $txt2.Length
    $espacos = [math]::Max(0, [math]::Floor(($Host.UI.RawUI.WindowSize.Width - $larguraTotal) / 2))

    # Imprimimos a primeira parte com o recuo, sem pular linha
    Write-Host (" " * $espacos + $txt1) -ForegroundColor $cor1 -NoNewline
    
    # Imprimimos a segunda parte logo em seguida
    Write-Host $txt2 -ForegroundColor $cor2
}




$LarguraMenu = 50  # Largura fixa da caixa do menu

# Pega a largura atual da janela do terminal para centralizar
$WinWidth = $Host.UI.RawUI.WindowSize.Width
$MargemH = [math]::Max(0, [int](($WinWidth - $LarguraMenu) / 2))
$EspacoM = " " * $MargemH


# ===============================================
# INÍCIO DO MENU DE SELEÇÃO (Antes do while($true))
# ===============================================

do {
    Clear-Host
    Escrever-Divisor -Cor White
    Escrever-CabecalhoSBT
    Escrever-Divisor -Cor White
    Write-Host ''
    Write-Host ''
    # --- MOLDURA SUPERIOR ---
Write-Host "$EspacoM┏$($('━' * ($LarguraMenu - 2)))┓" -ForegroundColor Yellow

# --- BANNER INTERNO (TÍTULO DO MENU) ---
$TituloInterno = " MENU DE OPERAÇÕES "
$PadTit = [int](($LarguraMenu - 2 - $TituloInterno.Length) / 2)
$SobraTit = $LarguraMenu - 2 - $TituloInterno.Length - $PadTit

Write-Host "$EspacoM┃" -NoNewline -ForegroundColor Yellow
Write-Host (" " * $PadTit + $TituloInterno + " " * $SobraTit) -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host "┃" -ForegroundColor Yellow

# --- DIVISÓRIA INTERNA ---
Write-Host "$EspacoM┣$($('━' * ($LarguraMenu - 2)))┫" -ForegroundColor Yellow

# --- LISTA DE OPÇÕES (ALINHAMENTO AUTOMÁTICO) ---
$Opcoes = @(
    "1. Grade de programação +SBT Raiz",
    "2. Grade de programação +SBT Novelas",
    "3. Lista de programas On Demand",
    "4. +SBT Downloader",
    "5. Gravar +Raiz",
    "6. Gravar SBT",
    "7. Gravar SBT News"
)

foreach ($Op in $Opcoes) {
    # O PadRight preenche com espaços até a borda direita perfeitamente
    $Conteudo = "  $Op".PadRight($LarguraMenu - 2)
    Write-Host "$EspacoM┃" -NoNewline -ForegroundColor Yellow
    Write-Host $Conteudo -NoNewline -ForegroundColor White
    Write-Host "┃" -ForegroundColor Yellow
}

# --- MOLDURA INFERIOR ---
Write-Host "$EspacoM┗$($('━' * ($LarguraMenu - 2)))┛" -ForegroundColor Yellow

# --- PROMPT DE ENTRADA ---
Write-Host "`n$EspacoM" -NoNewline
Write-Host " Selecione uma opção: " -ForegroundColor Yellow -NoNewline
$MenuChoice = Read-Host

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

    # Define o nome do arquivo como .csv
    $FileName = "Programacao_SBTRaiz_$(Get-Date -Format 'yyyyMMdd').csv"
    $FullPath = Join-Path -Path $DocumentsPath -ChildPath $FileName

    Write-Host "`nIniciando a exportação para CSV..." -ForegroundColor Cyan

    # Expandimos todos os grupos em uma única lista plana para o CSV
    $AllRows = foreach ($Day in $GroupedData) {
        $Day.Group | Sort-Object StartTimeMs | ForEach-Object {
            [PSCustomObject]@{
                Data           = $_.DateKey
                Hora           = $_.HoraPura
                Titulo         = $_.Title
                Episodio       = $_.EpisodeName
                MediaID        = $_.MediaId
            }
        }
    }

    try {
        # Exporta para CSV usando o delimitador ponto e vírgula (padrão Excel Brasil)
        # O parâmetro -NoTypeInformation remove o cabeçalho chato do PowerShell
        $AllRows | Export-Csv -Path $FullPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        
        Write-Host "`nArquivo CSV gerado com sucesso em: $FullPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Erro ao salvar o arquivo CSV: $($_.Exception.Message)"
    }
    
    Write-Host "`n Pressione ENTER para voltar ao menu..." -ForegroundColor Magenta
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
    Escrever-Divisor -Cor Magenta
    Escrever-Centro "PROGRAMAÇÃO +SBT RAIZ" -Cor Cyan
    Escrever-Divisor -Cor Magenta
    
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
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    while ($true) {

	# Exibe a primeira parte em cor padrão
	Write-Host "Digite o número do dia, " -NoNewline

	# Exibe a parte específica em Verde
	Write-Host "S para salvar a programação" -ForegroundColor Green -NoNewline

	Write-Host ", ou " -NoNewline

	Write-Host "Q para Sair " -ForegroundColor Red -NoNewline

	# Exibe o restante e abre o campo de entrada
	$Selection = Read-Host

        if ($Selection -eq 'q') {
            return $null
        }

        # NOVO: Se o usuário digitar 's', retornamos um sinal especial
        if ($Selection -eq 's') {
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
    Escrever-Divisor
    Escrever-Centro "+SBT Raiz" -Cor Cyan
    Escrever-Divisor
    Write-Host " Grade de $ReadableDate" -ForegroundColor Yellow
    Escrever-Divisor

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
    Escrever-Divisor
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
		Escrever-Divisor -Cor White
		Escrever-Centro "+SBT Downloader" -Cor Cyan
		Escrever-Divisor -Cor White
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
                Escrever-Divisor -Cor White
		Escrever-Centro "ESCOLHER A QUALIDADE" -Cor Yellow
		Escrever-Divisor -Cor White
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
        $duracaoSegundos = [double]$FFProbeOutput.format.duration
        $duracaoFormatada = Format-Duration $duracaoSegundos
    }

    Clear-Host
    Escrever-Divisor -Cor White
    Escrever-Centro "ESCOLHER A QUALIDADE" -Cor Yellow
    Escrever-Divisor -Cor White
    Write-Host ""

    Write-Host "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    Write-Host "┃" -NoNewline
    Write-Host "Duração: " -NoNewline -ForegroundColor White
    Write-Host "$duracaoFormatada" -ForegroundColor Yellow -NoNewline
    Write-Host "                                                              ┃"
    Write-Host "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"

    # --- LISTAGEM DAS QUALIDADES (VERSÃO MELHORADA) ---
    foreach ($grupo in $streamsAgrupados) {
        
        $bitrateVariant = $grupo.Name
        $programIdDisplay = if ($programIdMap.ContainsKey($bitrateVariant)) { $programIdMap[$bitrateVariant] } else { "N/A" }

        # Busca o vídeo para definir a cor da resolução no cabeçalho
        $videoStreamHeader = $grupo.Group | Where-Object { $_.codec_type -eq "video" } | Select-Object -First 1
        $resolucaoCabecalho = "N/A"
        $corResolucao = "White"

        if ($videoStreamHeader -and $videoStreamHeader.height) {
            $altura = [int]$videoStreamHeader.height
            $resolucaoCabecalho = "$($altura)p"
            if ($altura -ge 720) { $corResolucao = "Green" }
            elseif ($altura -ge 480) { $corResolucao = "Yellow" }
            else { $corResolucao = "Red" }
        }

        Write-Host "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
        Write-Host "┃" -NoNewline
        Write-Host -NoNewline " PROGRAM ID: " -ForegroundColor Magenta
        Write-Host -NoNewline "$programIdDisplay" -ForegroundColor Yellow
        
        # --- CÁLCULO DINÂMICO DE ESPAÇAMENTO ---
        # A largura total interna da box é 78 caracteres. 
        # Subtraímos o texto fixo " PROGRAM ID: " (13) e o tamanho do ID.
        $larguraRestante = 78 - 13 - $programIdDisplay.ToString().Length - $resolucaoCabecalho.Length
        
        if ($resolucaoCabecalho -ne "N/A") {
            Write-Host (" " * $larguraRestante) -NoNewline
            Write-Host "$resolucaoCabecalho" -ForegroundColor $corResolucao -NoNewline
            Write-Host " ┃"
        } else {
            Write-Host (" " * (78 - 13 - $programIdDisplay.ToString().Length)) -NoNewline
            Write-Host " ┃"
        }
        Write-Host "┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫"

        foreach ($stream in ($grupo.Group | Sort-Object codec_type)) {
            $indiceStream = $stream.index
            $tipoCodec = $stream.codec_type
            $nomeCodec = $stream.codec_name
            $variantBitrateValue = if ($stream.tags -and $stream.tags.variant_bitrate) { $stream.tags.variant_bitrate } else { $null }

            Write-Host "┃" -NoNewline
            $linhaSaida = " [Stream #$indiceStream - $($tipoCodec.ToUpper())] $nomeCodec"

            switch ($tipoCodec) {
                "video" {
                    # Lógica de FPS (Melhorada)
                    $fps = "N/A"
                    if ($stream.avg_frame_rate -and $stream.avg_frame_rate -ne "0/0") {
                        $parts = $stream.avg_frame_rate.Split('/')
                        if ($parts.Count -eq 2 -and [double]$parts[1] -ne 0) {
                            $fps = [math]::Round(([double]$parts[0] / [double]$parts[1]), 2)
                        }
                    }

                    # Bitrate Mbps (com Fallback)
                    $bitrateMbC = 0
                    if ($variantBitrateValue) {
                        $bitrateMbC = [math]::Truncate(([double]$variantBitrateValue / 1000000) * 100) / 100
                    }
                    $linhaSaida += " | $($stream.width)x$($stream.height) | ${fps} fps | Bitrate: {0:N2} Mbps" -f $bitrateMbC
                }
                "audio" {
                    # Canais e Sample Rate (Padrão BR)
                    $canaisRaw = if ($stream.channels) { [int]$stream.channels } else { 0 }
                    $canaisTexto = switch ($canaisRaw) {
                        1 { "1.0 Mono" }
                        2 { "2.0 Estéreo" }
                        6 { "5.1 Surround" }
                        8 { "7.1 Surround" }
                        default { "$canaisRaw canais" }
                    }
                    $sampleRateRaw = if ($stream.sample_rate) { [int]$stream.sample_rate } else { 0 }
                    $sampleRateFinal = if ($sampleRateRaw -gt 0) { ("{0:N0} Hz" -f $sampleRateRaw).Replace(",", ".") } else { "N/A" }

                    $linhaSaida += " | $canaisTexto | $sampleRateFinal"
                }
            }
            Write-Host $linhaSaida
        }
        Write-Host "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
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
                Escrever-Divisor -Cor White
		Escrever-Centro "INICIANDO O DOWNLOAD" -Cor Cyan
		Escrever-Divisor -Cor White
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
                Escrever-Divisor -Cor White
                Write-Host ''
                Escrever-Centro "DOWNLOAD CONCLUÍDO!" -Cor Green
                Write-Host ''
		Escrever-Divisor -Cor White
                Write-Host ''
                Write-Host "Pressione Enter para baixar outro vídeo..."
                Read-Host | Out-Null
            }
            
            # --- FIM DO CÓDIGO DO +SBT DOWNLOADER (MOVIDO) ---
            
        }
	"5" {
		& .\gravar_raiz.ps1 

            # Pausa para o usuário ver o resultado
            # Read-Host "Pressione Enter para voltar ao Menu"
	}
	"6" {
		& .\gravar_sbt.ps1 

            # Pausa para o usuário ver o resultado
            # Read-Host "Pressione Enter para voltar ao Menu"
	}
	"7" {
		& .\gravar_sbtnews.ps1 

            # Pausa para o usuário ver o resultado
            # Read-Host "Pressione Enter para voltar ao Menu"
	}
        default {
            Write-Host "Opção inválida. Por favor, digite 1, 2, 3, 4 ou 5." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($true) # O loop agora é 'while ($true)' pois a Opção 3 contém seu próprio 'break' para voltar.