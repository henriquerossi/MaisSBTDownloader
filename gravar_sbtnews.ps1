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

# Link da Live fixo
$LINK_VIDEO = "https://dai.google.com/linear/hls/event/xeOYqkegRUyawPuCPaN2Rw/master.m3u8"

while ($true) {
    Clear-Host
    Escrever-Divisor -Cor White
    Escrever-Centro "GRAVAR SBT News" -Cor Cyan
    Escrever-Divisor -Cor White
    Write-Host ''
    Write-Host "Aguarde, analisando a transmissão..." -NoNewline

    # 1. Detecta Resolução, FPS e Bitrate
    $FFProbeOutput = .\ffprobe -v quiet -print_format json -show_streams -show_programs $LINK_VIDEO | ConvertFrom-Json
    
    if (-not $FFProbeOutput -or -not $FFProbeOutput.streams) {
        Write-Host "`nErro: Sinal não detectado. Verifique o link." -ForegroundColor Red
        Write-Host ''
        Write-Host "Pressione 'ENTER' para tentar novamente ou 'ESC' para sair..." -NoNewline
        $teclaErro = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($teclaErro.VirtualKeyCode -eq 27) { break }
        continue
    }

    $maiorStream = $FFProbeOutput.streams | Where-Object { $_.codec_type -eq "video" } | Sort-Object height -Descending | Select-Object -First 1
    
    # Lógica FPS
    $fpsFinal = "N/A"
    if ($maiorStream.r_frame_rate -and $maiorStream.r_frame_rate -ne "0/0") {
        $partes = $maiorStream.r_frame_rate.Split('/')
        if ($partes.Count -eq 2 -and [double]$partes[1] -ne 0) {
            $fpsFinal = [math]::Round([double]$partes[0] / [double]$partes[1])
        }
    }

    # Lógica Bitrate
    $bitrateRaw = 0
    if ($maiorStream.tags.variant_bitrate) { $bitrateRaw = $maiorStream.tags.variant_bitrate }
    elseif ($maiorStream.bit_rate) { $bitrateRaw = $maiorStream.bit_rate }
    $bitrateMb = [math]::Truncate(($bitrateRaw / 1000000) * 100) / 100

    # Formatação e Cores
    $qualidadeTexto = if ($maiorStream) { "$($maiorStream.height)p@$($fpsFinal)fps" } else { "Qualidade Desconhecida" }
    $bitrateTexto = "{0:N2} Mb/s" -f $bitrateMb

    $corQualidade = "Red"
    if ($maiorStream.height -ge 720) { $corQualidade = "Green" } 
    elseif ($maiorStream.height -ge 480) { $corQualidade = "Yellow" }

    Write-Host "`rSinal detectado: " -NoNewline; 
    Write-Host $qualidadeTexto -ForegroundColor $corQualidade -NoNewline
    Write-Host " " -ForegroundColor White -NoNewline
    Write-Host $bitrateTexto -ForegroundColor Cyan -NoNewline
    Write-Host "    " -ForegroundColor White
    Write-Host ''

    # 2. Geração do Nome e Confirmação de Início
    $DataHora = Get-Date -Format "dd-MM-yyyy_HH-mm-ss"
    $NOME_ARQUIVO = "SBTNews_$DataHora.ts"
    
    Write-Host ''
    Write-Host "A gravação será salva como: " -NoNewline; Write-Host $NOME_ARQUIVO -ForegroundColor Magenta
    Write-Host ''
    Write-Host ('━' * 59) -ForegroundColor White
    Write-Host "Pressione qualquer tecla para INICIAR ou 'ESC' para sair..." -NoNewline
    $teclaInicio = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    if ($teclaInicio.VirtualKeyCode -eq 27) { break }

    # 3. Iniciar Gravação
    $OutputPath = Join-Path -Path $env:USERPROFILE\Documents -ChildPath $NOME_ARQUIVO
    Clear-Host
    Escrever-Divisor -Cor White
    Escrever-Centro "GRAVAR SBT News" -Cor Cyan
    Escrever-Divisor -Cor White
    Write-Host ''
    Escrever-Centro "Iniciando gravação..." -Cor Yellow
    Write-Host ''
    Write-Host ''
    Write-Host ''

    try {
        # O FFmpeg seleciona a melhor qualidade automaticamente se não usarmos o parâmetro -map
        .\ffmpeg -user_agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36" -i $LINK_VIDEO -c copy -hide_banner $OutputPath 
    } catch {
        Write-Host "Ocorreu um erro durante a execução do FFmpeg." -ForegroundColor Red
    }

    Write-Host ''
    Escrever-Divisor -Cor White
    Write-Host ''
    Escrever-Centro "GRAVAÇÃO CONCLUÍDA" -Cor Green
    Write-Host ''
    Escrever-Divisor -Cor White
    Write-Host ''
    Write-Host "Pressione 'ENTER' para voltar ao início ou 'ESC' para fechar o programa..." -NoNewline
    
    $teclaFinal = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    if ($teclaFinal.VirtualKeyCode -eq 27) { break }
}