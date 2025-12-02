# Configurações de URL
$URI_BASE_PROGRAMA = "https://content-api-prod.maissbt.com.br/show/"
$URI_SUFIXO_EPISODIOS = "/episodes" # Adiciona o sufixo necessário

# Lista completa de programas (Consolidada e pronta para ordenação)
# NOTA SOBRE ENCODING: Caracteres especiais foram simplificados (ex: 'Ô' para 'O', 'Ó' para 'O') 
# para evitar erros de 'ParserError' em ambientes PowerShell mais antigos (PowerShell 5.1 no Windows)
# que não usam UTF-8 por padrão. Se possível, execute este script usando 'pwsh' (PowerShell Core).
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
    [PSCustomObject]@{Nome="Ô Coitado..."; ID="6350579085112"}, # Corrigido de Ô Coitado...
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
    [PSCustomObject]@{Nome="Amor e Odio"; ID="6345113207112"}, # Corrigido de Amor e Ódio
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
    Write-Host "                  +SBT On Demand" -ForegroundColor Yellow
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
        # Prompt atualizado para aceitar apenas 0 para sair.
        Write-Host "  Digite o número do programa desejado (ou 0 para sair):" -ForegroundColor Green -NoNewline
        $escolha = Read-Host
        
        # 1. Verifica se o usuário quer sair ('0')
        if ($escolha -ceq '0') {
            return $null # Sai do script
        }
        
        # 2. Verifica se a entrada é um número de programa válido
        if ($escolha -match '^\d+$') {
            $indice = [int]$escolha
            
            if ($indice -ge 1 -and $indice -le $programasOrdenados.Count) {
                # Retorna o OBJETO completo (ID e Nome) do programa escolhido
                return $programasOrdenados[$indice - 1]
            }
            else {
                Write-Host "Opção inválida. Tente novamente." -ForegroundColor Red
            }
        }
        else {
            # Mensagem de erro atualizada para aceitar apenas números ou 0.
            Write-Host "Entrada inválida. Digite um número ou 0." -ForegroundColor Red
        }
    } while ($true)
}

# --- Função 2: Consulta a API de Episódios, Exibe e Oferece a Opção de Salvar ---
function List-Episodes ($programId, $programName) {
    
    # 1. Monta o link completo
    $urlCompleta = "$URI_BASE_PROGRAMA$programId$URI_SUFIXO_EPISODIOS"

    Clear-Host
    Write-Host "`nConsultando episódios de $programName..." -ForegroundColor Green
    
    # 2. Faz a requisição à API
    try {
        $jsonEpisodios = Invoke-RestMethod -Uri $urlCompleta -Method Get
    }
    catch {
        Write-Error "Erro ao consultar a API de episódios (HTTP Error): $($_.Exception.Message)"
        Write-Host " Pressione [Enter] para retornar ao menu..." -ForegroundColor Magenta
        Read-Host | Out-Null
        return
    }

    # 3. Extrai a lista de vídeos/episódios
    $episodios = $jsonEpisodios.items
    if ($null -eq $episodios -or $episodios.Count -eq 0) {
        $episodios = $jsonEpisodios.videos
    }

    if ($null -eq $episodios -or $episodios.Count -eq 0) {
        Write-Host "Nenhum episódio encontrado para o programa '$programName' (ID: $programId), ou a estrutura JSON está incorreta." -ForegroundColor Red
        Write-Host " Pressione [Enter] para retornar ao menu..." -ForegroundColor Magenta
        Read-Host | Out-Null
        return
    }

    # 4. Prepara os dados desejados (name e id)
    $dadosParaExibir = $episodios | Select-Object -Property @{N='Nome do Episódio';E={$_.name}}, @{N='ID';E={$_.id}}
    
    # Gera a string formatada (Tabela) para exibição e salvamento
    # Out-String é crucial para capturar a saída formatada pela Format-Table
    $listaFormatada = $dadosParaExibir | Format-Table -AutoSize | Out-String

    Clear-Host
    # 5. Exibe o cabeçalho e a lista formatada
    Write-Host ''
    Write-Host "`t$programName" -ForegroundColor Cyan
    Write-Host ('━' * 60)
    Write-Host ""
    Write-Host $listaFormatada

    # 6. Opção de salvar
    Write-Host ('━' * 60)
    do {
        # 'S' para salvar permanece inalterado e agora é case-insensitive.
        $acao = Read-Host " Pressione [Enter] para retornar ao menu, ou digite [S] para Salvar"
        
        # Verifica se é Enter (vazio) ou 'S' (case-INSENSITIVE)
        if ($acao -eq "" -or $acao -eq 'S') { 
            break # Sai do loop do/while
        }
        Write-Host "Opção inválida. Pressione [Enter] ou digite [S]." -ForegroundColor Red
    } while ($true)

    # 7. Lógica de Salvamento
    if ($acao -eq 'S') { 
        
        # 7.1. Prepara o conteúdo completo para salvar, incluindo o nome do programa
        $cabecalho = "`t$programName`n"
        $separador = ("=" * 20) + "========================================"
        # O conteúdo completo agora tem o cabeçalho e a tabela
        $conteudoCompleto = $cabecalho + $separador + "`n`n" + $listaFormatada 

        # --- LÓGICA DE GERAÇÃO DE NOME DE ARQUIVO SEM ACENTOS (ATUALIZADA PARA COMPATIBILIDADE COM PS 5.1) ---
        
        # 1. Normaliza para a forma decomposta (e.g., 'á' vira 'a' + acento).
        $normalizedName = $programName.Normalize([System.Text.NormalizationForm]::FormD)
        
        # 2. Remove todas as marcas diacríticas não espaçadas (\p{Mn} - Mark, non-spacing).
        # Este regex é a forma compatível para remover acentos após a normalização.
        $nonAccentedName = $normalizedName -replace "\p{Mn}", "" 
        
        # 3. Limpeza de nome de arquivo: substitui caracteres não permitidos com '_'
        # Remove outros símbolos (mantém letras, números e espaços)
        $nomeLimpo = $nonAccentedName -replace '[^a-zA-Z0-9\s]', '' 
        # Troca espaços por underline
        $nomeLimpo = $nomeLimpo -replace '\s+', '_' 
        
        # 4. Limpa underlines extras/iniciais/finais. O cast [string] resolve o erro de método Trim() em array.
        $nomeLimpo = ([string]($nomeLimpo -replace '__+', '_')).Trim('_') 
        
	$dataAtual = (Get-Date).ToString("yyyyMMdd")

        $nomeArquivoBase = "$($nomeLimpo)_$dataAtual.txt"
        
        # OBTÉM O CAMINHO DA PASTA DOCUMENTOS usando a enumeração SpecialFolder
        $caminhoDocumentos = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments)
        
        # Combina o caminho da pasta Documentos com o nome do arquivo para obter o caminho completo
        $caminhoCompleto = Join-Path -Path $caminhoDocumentos -ChildPath $nomeArquivoBase
        
        try {
            # Salva o conteúdo completo no caminho completo especificado
            $conteudoCompleto | Out-File -FilePath $caminhoCompleto -Encoding UTF8
            Write-Host "`nLista salva com sucesso em: $($caminhoCompleto)" -ForegroundColor Yellow
        }
        catch {
            Write-Host "`nERRO ao salvar o arquivo: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Pausa final para o usuário ver o resultado/confirmação antes de voltar ao menu
    Write-Host "`n`n Pressione [Enter] para voltar..." -ForegroundColor Magenta
    Read-Host | Out-Null
}

# ----------------- INÍCIO DO SCRIPT PRINCIPAL -----------------

do {
    # 1. Obtém o OBJETO do programa escolhido pelo usuário
    $programaEscolhido = Get-ProgramIdFromMenu

    # 2. Se o usuário escolheu 0 (saiu), interrompe o loop
    if ($null -eq $programaEscolhido) {
        break
    }
    
    # 3. Lista os episódios (a função agora inclui a opção de salvar e a pausa final)
    List-Episodes -programId $programaEscolhido.ID -programName $programaEscolhido.Nome
    
} while ($true)