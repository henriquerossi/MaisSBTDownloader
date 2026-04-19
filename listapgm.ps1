# Configurações de API
$URI_BASE = "https://content-api-prod.maissbt.com.br/show/"
$URI_SUFIXO = "/episodes"

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


function Search-SBT {
    param([string]$Termo)
    
    # Converte espaços em %20 e trata caracteres especiais
    $TermoEscapado = [uri]::EscapeDataString($Termo)

    # Aguardando o link oficial que você mencionou, mas a lógica de busca será esta:
    $urlBusca = "https://content-api-prod.maissbt.com.br/videos/search?q=$TermoEscapado&showOffset=0&videoOffset=0&limit=100" 
    
    try {
        Clear-Host
        Escrever-Divisor -Cor Yellow
        Escrever-Centro "Termo pesquisado: $Termo" -Cor Yellow
        Escrever-Divisor -Cor Yellow
        Write-Host " Pesquisando...`n" -ForegroundColor Gray

        $resp = Invoke-RestMethod -Uri $urlBusca -Method Get -ErrorAction Stop
        
        # Mapeia os campos conforme o seu JSON
        $resultados = $resp.videos | ForEach-Object {
            [PSCustomObject]@{
                Programa  = $_.parentShow.name
		# --- NOVO: Captura o aviso do programa ---
        	AvisoProg = $_.parentShow.custom_fields.title_custom_message
                Episodio  = $_.name
                MediaID   = $_.id
                Descricao = $_.description
		# --- LINHAS MODIFICADAS PARA ORDENAÇÃO ---
        	Temporada = [int]$_.custom_fields.season_order_number
        	OrdemEp   = [int]$_.custom_fields.episode_order_number
		# --- CAMPO DA MENSAGEM ---
        	Mensagem  = $_.custom_fields.video_custom_message
            }
        }

        if ($null -eq $resultados -or $resultados.Count -eq 0) {
            Write-Host " [!] Nenhum episódio encontrado com o termo '$Termo'." -ForegroundColor Red
        } else {
            # Exibe o total de resultados logo no início
            Write-Host " Encontrados $($resultados.Count) resultados para sua busca:`n" -ForegroundColor Green

            # Agrupa por Programa (ex: Geração Chiquititas)
            $agrupados = $resultados | Group-Object Programa

            foreach ($grupo in $agrupados) {
                # Nome do programa em destaque (Ciano)
                Write-Host " » $($grupo.Name)" -ForegroundColor Cyan -NoNewline
		# --- NOVO: Exibe o Aviso do Programa (title_custom_message) ---
    		# Pegamos do primeiro item do grupo, já que o aviso é o mesmo para todos
    		$avisoPrograma = $grupo.Group[0].AvisoProg
    		if (-not [string]::IsNullOrWhiteSpace($avisoPrograma)) {
        		Write-Host "  $avisoPrograma" -ForegroundColor Red -NoNewline
    		}
		Write-Host ""
		$episodiosOrdenados = $grupo.Group | Sort-Object Temporada, OrdemEp
                
                foreach ($item in $episodiosOrdenados) {
                    # Episódio em Branco e Media ID na cor padrão do sistema
                    Write-Host "   $($item.Episodio)" -ForegroundColor White -NoNewline
			# 2. Exibe a Mensagem em Vermelho (se existir) logo após o episódio
    			if (-not [string]::IsNullOrWhiteSpace($item.Mensagem)) {
        			Write-Host "  $($item.Mensagem)" -ForegroundColor Red -NoNewline
    			}
		    Write-Host ""
                    Write-Host "     Media ID: " -NoNewline
                    Write-Host "$($item.MediaID)" -ForegroundColor Magenta
                    
                    # Descrição em cinza logo abaixo
                    if (-not [string]::IsNullOrWhiteSpace($item.Descricao)) {
                        Write-Host "        $($item.Descricao)" -ForegroundColor DarkYellow
                    }
                    Write-Host "" # Linha em branco para separar os episódios
                }
                # Linha divisória entre programas diferentes
                Write-Host (" " + "—" * ($Host.UI.RawUI.WindowSize.Width - 5)) -ForegroundColor DarkGray
            }
        }
    } catch {
        Write-Host " [!] Erro ao fazer a busca." -ForegroundColor Red
    }

    Write-Host "`n"
    # Escrever-Divisor -Cor Yellow
    Read-Host " Pressione Enter para voltar ao menu On Demand"
}



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
    @{Nome="Tentação"; ID="6365814210112"},
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
    @{Nome="E Agora, Quem Vai Ficar Com a Mamãe?"; ID="35564ab6-bb20-45e0-86ea-828bc79c89c8"},
    @{Nome="Gabi Quase Proibida"; ID="6345111467112"},
    @{Nome="Rouge: A História"; ID="6366454942112"},
    @{Nome="Sabadão Sertanejo"; ID="6349198049112"},
    @{Nome="SBT Repórter"; ID="ac01dd5d-2444-4ba7-a374-c889f968cd9e"},
    @{Nome="Topa Tudo Por Dinheiro"; ID="6359582776112"},
    @{Nome="Curtindo uma Viagem"; ID="6348824665112"},
    @{Nome="Meu Cunhado"; ID="6349812463112"},
    @{Nome="Silvio Santos: Vale Mais do que Dinheiro"; ID="6360531975112"},
    @{Nome="Hebe, a Cara da Coragem"; ID="6359702801112"},
    @{Nome="Divina Christina"; ID="6360530851112"},
    @{Nome="Gugu, Toninho e Augusto"; ID="6360533397112"},
    @{Nome="Um Gênio Chamado Jô"; ID="6360532840112"},
    @{Nome="Shaun, o Carneiro"; ID="6359466483112"},
    @{Nome="Amor e Ódio"; ID="6345113207112"},
    @{Nome="Revelação"; ID="6373505944112"},
    @{Nome="Amigas e Rivais"; ID="6345112214112"},
    @{Nome="Cristal"; ID="6345114834112"},
    @{Nome="Maria Esperança"; ID="6339337508112"},
    @{Nome="Amor e Revolução"; ID="6345122408112"},
    @{Nome="Pícara Sonhadora"; ID="6345122711112"},
    @{Nome="Canavial de Paixões"; ID="6345111275112"},
    @{Nome="Pequena Travessa"; ID="6343455776112"},
    @{Nome="Esmeralda"; ID="6336570395112"},
    @{Nome="Marisol"; ID="6345119695112"},
    @{Nome="TV Animal"; ID="6348823152112"},
    @{Nome="Lendas Urbanas"; ID="6376442789112"},
    @{Nome="Programa do Ratinho"; ID="6355031112112"},
    @{Nome="Namoro na TV"; ID="6350564829112"},
    @{Nome="Esmeralda México"; ID="8c3f0d0a-6ed7-496a-bd7f-2d3a97a867d1"},
    @{Nome="Chaves"; ID="6363758492112"},
    @{Nome="Chapolin"; ID="6363759535112"},
    @{Nome="Alegrifes e Rabujos"; ID="6367956677112"},
    @{Nome="The Noite com Danilo Gentili"; ID="6354828605112"},
    @{Nome="Viva a Noite"; ID="6348751527112"},
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
    Escrever-Divisor -Cor White
    Escrever-Centro "+SBT On Demand" -Cor Yellow
    Escrever-Divisor -Cor White
    Write-Host ''
    # 1. Preparação dos dados
    $progs = $PROGRAM_LIST | Sort-Object Nome
    $total = $progs.Count
    $metade = [Math]::Ceiling($total / 2)

    # 2. Cálculos de centralização
    $larguraJanela = $Host.UI.RawUI.WindowSize.Width
    $larguraConteudo = 85 # Largura total das duas colunas + espaços
    $margemEsquerda = [Math]::Max(0, [int](($larguraJanela - $larguraConteudo) / 2))
    $espacoParaCentralizar = " " * $margemEsquerda

    # 4. Loop para exibição em duas colunas com recuo centralizado
    for ($i = 0; $i -lt $metade; $i++) {
    
    # Coluna 1
    $nome1 = $progs[$i].Nome
    $num1 = $i + 1
    $col1 = "{0,2}. {1,-38}" -f $num1, $nome1
    
    # Coluna 2
    $idx2 = $i + $metade
    if ($idx2 -lt $total) {
        $nome2 = $progs[$idx2].Nome
        $num2 = $idx2 + 1
        $col2 = "{0,2}. {1}" -f $num2, $nome2
    } else {
        $col2 = ""
    }

    # Exibe a linha com o recuo da margem esquerda
    Write-Host "$espacoParaCentralizar$col1 $col2"
}

    Write-Host ""
    Escrever-Divisor -Cor White
    Write-Host "[S] Salvar todos os programas (.zip)" -ForegroundColor Cyan
    Write-Host "[B] Buscar episódios" -ForegroundColor Magenta
    Write-Host "[X] Sair" -ForegroundColor Red
    
    $op = Read-Host "`nEscolha uma opção"
    if ($op -eq "x") { break }

    # NOVA OPÇÃO DE BUSCA
    if ($op -eq "b") {
        Write-Host ""
	Escrever-Divisor -Cor Blue
	Escrever-Centro "Buscar episódios" -Cor White
	Escrever-Divisor -Cor Blue
        
	$termoBusca = Read-Host "`nDigite o termo para buscar ou aperte ENTER para voltar"
        if (-not [string]::IsNullOrWhiteSpace($termoBusca)) {
            Search-SBT -Termo $termoBusca
        }
        continue # Volta para o início do loop (exibe o menu novamente)
    }
    
    # OPÇÃO EXTRAIR TUDO
    if ($op -eq "s") {
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

