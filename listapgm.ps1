# Configurações de API
$URI_BASE = "https://content-api-prod.maissbt.com.br/show/"
$URI_SUFIXO = "/episodes"

# Lista de programas
$PROGRAM_LIST = @(
    @{Nome="Porta dos Desesperados"; ID="6366549358112"},
    @{Nome="Programa Silvio Santos"; ID="6354517109112"},
    @{Nome="Em Nome do Amor"; ID="6350708330112"},
    @{Nome="Uma Rosa com Amor"; ID="6374236738112"},
    @{Nome="Domingo Legal"; ID="6349196961112"},
    @{Nome="Casos de Família"; ID="6347404315112"},
    @{Nome="Márcia"; ID="6362755845112"},
    @{Nome="Astros"; ID="6348825360112"},
    @{Nome="Entrevistas do Jô"; ID="6363647608112"},
    @{Nome="Hebe"; ID="6348739201112"},
    @{Nome="Fala Dercy"; ID="6363302025112"},
    @{Nome="Programa Livre"; ID="6348749639112"},
    @{Nome="Bozo"; ID="6369272558112"},
    @{Nome="Casa da Angélica"; ID="6366548209112"},
    @{Nome="Show Maravilha"; ID="6366373767112"},
    @{Nome="Eliana & Cia"; ID="6366856885112"},
    @{Nome="Show do Milhão"; ID="6350563425112"},
    @{Nome="Domingo no Parque"; ID="6362943595112"},
    @{Nome="Tentaçao"; ID="6365814210112"},
    @{Nome="Porta da Esperança"; ID="6362545123112"},
    @{Nome="Qual é a Música?"; ID="6351992333112"},
    @{Nome="Fantasia"; ID="6348742397112"},
    @{Nome="Passa ou Repassa"; ID="6348753850112"},
    @{Nome="A Escolinha do Golias"; ID="6350085817112"},
    @{Nome="Veja o Gordo"; ID="6349749014112"},
    @{Nome="Os Ossos do Barão"; ID="66858ec3-6397-40f3-a1ba-4077b290e6bd"},
    @{Nome="Chiquititas 97"; ID="6365875884112"},
    @{Nome="Fascinação"; ID="6374477392112"},
    @{Nome="Vende-se Um Véu de Noiva"; ID="6364708926112"},
    @{Nome="Seus Olhos"; ID="6361613423112"},
    @{Nome="Chiquititas 2013"; ID="6366293557112"},
    @{Nome="Carrossel"; ID="6345112835112"},
    @{Nome="Os Ricos Também Choram"; ID="6360108232112"},
    @{Nome="Ô Coitado..."; ID="6350579085112"},
    @{Nome="De Frente com Gabi"; ID="6348919056112"},
    @{Nome="A Praça é Nossa"; ID="6349811881112"},
    @{Nome="As Pupilas do Senhor Reitor"; ID="6376593590112"}
) | ForEach-Object { [PSCustomObject]$_ }

$caminhoDocs = [System.Environment]::GetFolderPath("MyDocuments")

# --- Função de Busca ---
function Get-Episodes($prog) {
    $url = "$URI_BASE$($prog.ID)$URI_SUFIXO"
    try {
        $resp = Invoke-RestMethod -Uri $url -Method Get -ErrorAction Stop
        $itens = $resp.items
        if ($null -eq $itens) { $itens = $resp.videos }
        return $itens | Select-Object @{N='Programa';E={$prog.Nome}}, @{N='Episodio';E={$_.name}}, @{N='ID_Video';E={$_.id}}
    } catch { return $null }
}

# --- Função de Salvamento ---
function Save-Csv($dados, $nome, $caminhoDestino) {
    # 1. Remove acentos (Normaliza para FormD e filtra caracteres de marca)
    $nomeSemAcento = $nome.Normalize([System.Text.NormalizationForm]::FormD)
    $nomeSemAcento = ($nomeSemAcento -replace '\p{Mn}', '')
    
    # 2. Troca o que não for letra ou número por "_"
    $nomeLimpo = $nomeSemAcento -replace '[^a-zA-Z0-9]', '_'
    
    # 3. Evita múltiplos underscores seguidos (ex: "___" vira "_")
    $nomeLimpo = $nomeLimpo -replace '_+', '_'
    $nomeLimpo = $nomeLimpo.Trim('_')

    $arquivo = Join-Path $caminhoDestino "$nomeLimpo.csv"
    $dados | Export-Csv -Path $arquivo -NoTypeInformation -Delimiter ";" -Encoding UTF8
    Write-Host "Salvo: $nomeLimpo.csv" -ForegroundColor Green
}

# --- Loop Principal ---
do {
    Clear-Host
    Write-Host ('━' * 70) -ForegroundColor White
    Write-Host "                  +SBT On Demand" -ForegroundColor Yellow
    Write-Host ('━' * 70) -ForegroundColor White
    Write-Host ''
    $progs = $PROGRAM_LIST | Sort-Object Nome
    for ($i=0; $i -lt $progs.Count; $i++) {
        Write-Host ("{0,2}. {1}" -f ($i+1), $progs[$i].Nome)
    }

    Write-Host ""
    Write-Host ('━' * 65)
    Write-Host "[99] Salvar todos os programas (.zip)" -ForegroundColor Cyan
    Write-Host "[0]  Sair" -ForegroundColor Red
    
    $op = Read-Host "`nEscolha um número"
    if ($op -eq "0") { break }
    
    # OPÇÃO EXTRAIR TUDO
    if ($op -eq "99") {
        $dataStr = Get-Date -Format "yyyyMMdd_HHmm"
        $pastaMassa = Join-Path $caminhoDocs "MaisSBT_Catalogo_$dataStr"
        New-Item -ItemType Directory -Path $pastaMassa | Out-Null

    $totalProgs = $progs.Count
	    Write-Host ""
            Write-Host ""
        for ($i = 1; $i -le $totalProgs; $i++) {
            $p = $progs[$i-1]
            
            # --- Lógica da Barra de Progresso Hacker ---
            $larguraBarra = 30
            $preenchido = [Math]::Floor(($i / $totalProgs) * $larguraBarra)
            $vazio = $larguraBarra - $preenchido
            $stringBarra = ("█" * $preenchido) + ("░" * $vazio)
            $percentual = [Math]::Floor(($i / $totalProgs) * 100)

            # Mostra o status atual (limpa a linha anterior com espaços se necessário)
            Write-Host "`rProgresso: [$stringBarra] $percentual% | $($p.Nome)".PadRight(100) -NoNewline -ForegroundColor Cyan

            # --- Processamento ---
            $dados = Get-Episodes $p
            if ($null -ne $dados -and $dados.Count -gt 0) {
                # Salva o arquivo sem poluir a tela
                Save-Csv $dados $p.Nome $pastaMassa | Out-Null
            } else {
                # Apenas ignora ou registra internamente, a barra continua subindo
            }
        }

        
        $zip = "$pastaMassa.zip"
        if ((Get-ChildItem $pastaMassa).Count -gt 0) {
            Write-Host "`nGerando arquivo .zip..." -ForegroundColor Yellow
            Compress-Archive -Path "$pastaMassa\*" -DestinationPath $zip -Force
            
            # --- AJUSTE: Remove a pasta após o ZIP ---
            Write-Host "Limpando pasta temporária..." -ForegroundColor Gray
            Remove-Item $pastaMassa -Recurse -Force
            
            Write-Host "`nTudo pronto! Arquivo gerado: $zip" -ForegroundColor Cyan
        } else {
            Write-Host "`nNenhum arquivo gerado. Nada para compactar." -ForegroundColor Red
            Remove-Item $pastaMassa -Recurse -Force
        }
        Read-Host "`nPressione Enter para voltar ao menu..."
    }
    # OPÇÃO INDIVIDUAL
    elseif ($op -match '^\d+$' -and [int]$op -le $progs.Count) {
        $p = $progs[[int]$op - 1]
        
        Clear-Host
        Write-Host ''
    	Write-Host "`t$($p.Nome)" -ForegroundColor Cyan
    	Write-Host ('━' * 68)
    	Write-Host ""
        
        $dados = Get-Episodes $p
        
        if ($null -ne $dados -and $dados.Count -gt 0) {
            $dados | Select-Object Episodio, ID_Video | Format-Table -AutoSize
            Write-Host ('━' * 60)
            $save = Read-Host "Deseja salvar este programa? (S/N)"
            if ($save -ieq "S") { 
                Save-Csv $dados $p.Nome $caminhoDocs 
                Write-Host "Arquivo .csv salvo em Documentos." -ForegroundColor Gray
            }
        } else {
            Write-Host "`nNenhum episódio encontrado para este programa no momento." -ForegroundColor Red
        }
        Read-Host "`nPressione Enter para voltar ao menu..."
    }
} while ($true)

Write-Host "`nEncerrando..." -ForegroundColor Gray
Start-Sleep -Seconds 1