# Configurações de URL
$URI_BASE_PROGRAMA = "https://content-api-prod.maissbt.com.br/show/"
$URI_SUFIXO_EPISODIOS = "/episodes" # Adiciona o sufixo necessário

# Lista completa de programas (Consolidada e pronta para ordenação)
$PROGRAM_LIST = @(
    [PSCustomObject]@{Nome="Porta dos Desesperados"; ID="6366549358112"},
    [PSCustomObject]@{Nome="Programa Silvio Santos"; ID="6354517109112"},
    [PSCustomObject]@{Nome="Em Nome do Amor"; ID="6350708330112"},
    [PSCustomObject]@{Nome="Uma Rosa com Amor"; ID="6374236738112"},
    [PSCustomObject]@{Nome="Domingo Legal"; ID="6349196961112"},
    [PSCustomObject]@{Nome="Casos de Família"; ID="6347404315112"},
    [PSCustomObject]@{Nome="Márcia"; ID="6362755845112"},
    [PSCustomObject]@{Nome="Astros"; ID="6348825360112"},
    [PSCustomObject]@{Nome="Entrevistas do Jô"; ID="6363647608112"},
    [PSCustomObject]@{Nome="Hebe"; ID="6348739201112"},
    [PSCustomObject]@{Nome="Fala Dercy"; ID="6363302025112"},
    [PSCustomObject]@{Nome="Programa Livre"; ID="6348749639112"},
    [PSCustomObject]@{Nome="Bozo"; ID="6369272558112"},
    [PSCustomObject]@{Nome="Casa da Angélica"; ID="6366548209112"},
    [PSCustomObject]@{Nome="Show Maravilha"; ID="6366373767112"},
    [PSCustomObject]@{Nome="Eliana & Cia"; ID="6366856885112"},
    [PSCustomObject]@{Nome="Show do Milhão"; ID="6350563425112"},
    [PSCustomObject]@{Nome="Domingo no Parque"; ID="6362943595112"},
    [PSCustomObject]@{Nome="Tentação"; ID="6365814210112"},
    [PSCustomObject]@{Nome="Porta da Esperança"; ID="6362545123112"},
    [PSCustomObject]@{Nome="Qual é a Música?"; ID="6351992333112"},
    [PSCustomObject]@{Nome="Fantasia"; ID="6348742397112"},
    [PSCustomObject]@{Nome="Passa ou Repassa"; ID="6348753850112"},
    [PSCustomObject]@{Nome="A Escolinha do Golias"; ID="6350085817112"},
    [PSCustomObject]@{Nome="Veja o Gordo"; ID="6349749014112"},
    [PSCustomObject]@{Nome="Os Ossos do Barão"; ID="66858ec3-6397-40f3-a1ba-4077b290e6bd"},
    [PSCustomObject]@{Nome="Chiquititas 97"; ID="6365875884112"},
    [PSCustomObject]@{Nome="Fascinação"; ID="6374477392112"},
    [PSCustomObject]@{Nome="Vende-se Um Véu de Noiva"; ID="6364708926112"},
    [PSCustomObject]@{Nome="Seus Olhos"; ID="6361613423112"},
    [PSCustomObject]@{Nome="Chiquititas 2013"; ID="6366293557112"},
    [PSCustomObject]@{Nome="Carrossel"; ID="6345112835112"},
    [PSCustomObject]@{Nome="Os Ricos Também Choram"; ID="6360108232112"},
    [PSCustomObject]@{Nome="E Agora, Quem Vai Ficar Com a Mamãe?"; ID="35564ab6-bb20-45e0-86ea-828bc79c89c8"},
    [PSCustomObject]@{Nome="Ô Coitado..."; ID="6350579085112"},
    [PSCustomObject]@{Nome="De Frente com Gabi"; ID="6348919056112"},
    [PSCustomObject]@{Nome="Gabi Quase Proibida"; ID="6345111467112"},
    [PSCustomObject]@{Nome="Rouge: A História"; ID="6366454942112"},
    [PSCustomObject]@{Nome="Sabadão Sertanejo"; ID="6349198049112"},
    [PSCustomObject]@{Nome="SBT Repórter"; ID="ac01dd5d-2444-4ba7-a374-c889f968cd9e"},
    [PSCustomObject]@{Nome="Topa Tudo Por Dinheiro"; ID="6359582776112"},
    [PSCustomObject]@{Nome="A Praça é Nossa"; ID="6349811881112"},
    [PSCustomObject]@{Nome="Curtindo uma Viagem"; ID="6348824665112"},
    [PSCustomObject]@{Nome="Meu Cunhado"; ID="6349812463112"},
    [PSCustomObject]@{Nome="Silvio Santos: Vale Mais do que Dinheiro"; ID="6360531975112"},
    [PSCustomObject]@{Nome="Hebe, a Cara da Coragem"; ID="6359702801112"},
    [PSCustomObject]@{Nome="Divina Christina"; ID="6360530851112"},
    [PSCustomObject]@{Nome="Gugu, Toninho e Augusto"; ID="6360533397112"},
    [PSCustomObject]@{Nome="Um Gênio Chamado Jô"; ID="6360532840112"},
    [PSCustomObject]@{Nome="Shaun, o Carneiro"; ID="6359466483112"},
    [PSCustomObject]@{Nome="Amor e Ódio"; ID="6345113207112"},
    [PSCustomObject]@{Nome="Revelação"; ID="6373505944112"},
    [PSCustomObject]@{Nome="Amigas e Rivais"; ID="6345112214112"},
    [PSCustomObject]@{Nome="Cristal"; ID="6345114834112"},
    [PSCustomObject]@{Nome="Maria Esperança"; ID="6339337508112"},
    [PSCustomObject]@{Nome="Amor e Revolução"; ID="6345122408112"},
    [PSCustomObject]@{Nome="Pícara Sonhadora"; ID="6345122711112"},
    [PSCustomObject]@{Nome="Canavial de Paixões"; ID="6345111275112"},
    [PSCustomObject]@{Nome="Pequena Travessa"; ID="6343455776112"},
    [PSCustomObject]@{Nome="Esmeralda"; ID="6336570395112"},
    [PSCustomObject]@{Nome="Marisol"; ID="6345119695112"},
    [PSCustomObject]@{Nome="TV Animal"; ID="6348823152112"},
    [PSCustomObject]@{Nome="As Pupilas do Senhor Reitor"; ID="6376593590112"}
)


# --- Função 1: Mostra o Menu Ordenado e Obtém a Escolha do Usuário ---
function Get-ProgramIdFromMenu {
    
    Clear-Host # Limpa a tela antes de exibir o menu
    Write-Host ('━' * 70) -ForegroundColor White
    Write-Host "                         +SBT On Demand" -ForegroundColor Yellow
    Write-Host ('━' * 70) -ForegroundColor White
    Write-Host ''    

    # ORDENAÇÃO: Ordena a lista de programas por nome
    $programasOrdenados = $PROGRAM_LIST | Sort-Object -Property Nome
    
    # Exibe o menu com índice para escolha
    $i = 1
    foreach ($programa in $programasOrdenados) {
        Write-Host "`t$i. $($programa.Nome)"
        $i++
    }
    
    Write-Host ""
    
    # Loop para garantir uma escolha válida
    do {
	Write-Host ''
	Write-Host "  Digite o número do programa desejado (ou 0 para voltar ao menu):" -ForegroundColor Green -NoNewline
        $escolha = Read-Host
        
        if ($escolha -match '^\d+$') {
            $indice = [int]$escolha
            
            if ($indice -eq 0) {
                return $null # Sai do script
            }
            
            if ($indice -ge 1 -and $indice -le $programasOrdenados.Count) {
                # Retorna o OBJETO completo (ID e Nome) do programa escolhido
                return $programasOrdenados[$indice - 1]
            }
            else {
                Write-Host "Opção inválida. Tente novamente." -ForegroundColor Red
            }
        }
        else {
            Write-Host "Entrada inválida. Digite um número." -ForegroundColor Red
        }
    } while ($true)
}

# --- Função 2: Consulta a API de Episódios e Exibe os Dados ---
function List-Episodes ($programId, $programName) {
    
    # 1. Monta o link completo, garantindo que não haja barras duplas.
    # Exemplo: https://content-api-prod.maissbt.com.br/show/6374236738112/episodes
    $urlCompleta = "$URI_BASE_PROGRAMA$programId$URI_SUFIXO_EPISODIOS"

    CLear-Host
    Write-Host "`nConsultando episódios de $programName" -ForegroundColor Green
    
    # 2. Faz a requisição à API
    try {
        $jsonEpisodios = Invoke-RestMethod -Uri $urlCompleta -Method Get
    }
    catch {
        Write-Error "Erro ao consultar a API de episódios (HTTP Error): $($_.Exception.Message)"
        return
    }

    # 3. Extrai a lista de vídeos/episódios. Tenta 'items' (comum em APIs) ou 'videos' (seu JSON de exemplo).
    $episodios = $jsonEpisodios.items
    if ($null -eq $episodios -or $episodios.Count -eq 0) {
        $episodios = $jsonEpisodios.videos
    }

    if ($null -eq $episodios -or $episodios.Count -eq 0) {
        Write-Host "Nenhum episódio encontrado para o programa '$programName' (ID: $programId), ou a estrutura JSON está incorreta." -ForegroundColor Red
        return
    }

    Clear-Host
    # 4. Exibe o nome do programa no cabeçalho
    Write-Host ''
    Write-Host "`t$programName" -ForegroundColor Cyan
    Write-Host ('━' * 60)
    Write-Host ""

    # 5. Exibe os campos desejados (name e id)
    $episodios | Select-Object -Property name, id | Format-Table -AutoSize
}

# ----------------- INÍCIO DO SCRIPT PRINCIPAL -----------------

do {
    # 1. Obtém o OBJETO do programa escolhido pelo usuário
    $programaEscolhido = Get-ProgramIdFromMenu

    # 2. Se o usuário escolheu 0 (saiu), interrompe o loop
    if ($null -eq $programaEscolhido) {
        break
    }
    
    # 3. Lista os episódios usando o ID e o Nome
    List-Episodes -programId $programaEscolhido.ID -programName $programaEscolhido.Nome

    # Pausa entre as consultas para dar tempo ao usuário de ler os resultados e voltar ao menu
    Write-Host ('━' * 60)
    Write-Host " Pressione [Enter] para retornar ao menu de programas..." -ForegroundColor Magenta
    Read-Host | Out-Null
    
} while ($true)

