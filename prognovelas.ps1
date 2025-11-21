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

    $FileName = "Programacao_SBTNovelas_$(Get-Date -Format 'yyyyMMdd').txt"
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
    Write-Host "                                PROGRAMAÇÃO +SBT NOVELAS             " -ForegroundColor Cyan
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
    Write-Host "                                        +SBT NOVELAS" -ForegroundColor Cyan
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
$JsonLink = "https://bridge.evrideo.tv/SBTEPG?ChannelUID=novelas&DurationHours=168"

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