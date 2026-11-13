# Jogos bem avaliados também são os que mais vendem?

Projeto acadêmico de Lógica e Matemática Discreta. O sistema transforma uma
única tabela de videogames em uma base de conhecimento e responde três
perguntas em SWI-Prolog. Python é usado somente para ETL: extração, limpeza e
geração dos fatos.

## Fonte e dados

A fonte é o dataset [Video Game Sales with
Ratings](https://www.kaggle.com/datasets/rush4ratio/video-game-sales-with-ratings).
Foi utilizado o arquivo `Video_Games_Sales_as_at_22_Dec_2016.csv`; as vendas
(`Global_Sales`) estão em milhões de unidades. O CSV original permanece
intacto.

O ETL seleciona uma única tabela-fonte e dez campos:

```prolog
jogo(Nome, Plataforma, Ano, Genero, Publicadora, VendasGlobais,
     NotaCritica, QtdCriticos, NotaUsuarios, QtdUsuarios).
```

Eles correspondem a `Name`, `Platform`, `Year_of_Release`, `Genre`,
`Publisher`, `Global_Sales`, `Critic_Score`, `Critic_Count`, `User_Score` e
`User_Count`. Valores ausentes são representados por `desconhecido`, e não
por zero.

Linhas sem nome são removidas. Duplicatas exatas nos dez campos manteriam um
único fato. Quando duas linhas têm a mesma identidade
`(Nome, Plataforma, Ano)` e valores selecionados diferentes, todas são
excluídas da base analítica e preservadas em `conflitos.json`. Essa política
exclui as duas linhas conflitantes de `Madden NFL 13`, `PS3`, `2012`, sem
escolher, somar ou calcular média entre elas.

## Fórmulas e perguntas

A nota do usuário é normalizada para a escala crítica:

```text
NotaUsuario100 = 10 * NotaUsuario
```

A discordância de um jogo é:

```text
Discordancia = |NotaCritica - NotaUsuario100|
```

A nota conjunta da pergunta 3 é:

```text
NotaConjunta = (NotaCritica + NotaUsuario100) / 2
```

1. **Pergunta 1:** agrupa por gênero, no intervalo de 2000--2016, exigindo
   notas válidas, pelo menos 10 avaliações da crítica e 50 de usuários.
   Considera apenas gêneros com pelo menos 20 registros e ordena pela
   discordância média.
2. **Pergunta 2:** agrupa por gênero e plataforma, com o mesmo intervalo e
   mínimos de avaliações. Considera grupos com pelo menos 10 registros,
   calcula as médias de crítica e usuários e a mediana das vendas (com
   repetições), selecionando jogos com notas acima das médias e vendas abaixo
   da mediana.
3. **Pergunta 3:** compara versões elegíveis do mesmo nome usando a nota
   conjunta. Retorna `versoes(Ordenadas, Melhores)`: a primeira lista contém
   todas as versões ordenadas; a segunda contém todas as vencedoras empatadas
   na maior nota. Menos de duas plataformas retorna
   `comparacao_insuficiente`.

Na pergunta 2, diferenças de até `1.0e-9` são tratadas como igualdade:

```prolog
NotaCritica - MediaCritica > 1.0e-9
NotaUsuario - MediaUsuario > 1.0e-9
MedianaVendas - Vendas > 1.0e-9
```

Os dados de origem e as médias não são arredondados. Eventual arredondamento
é apenas visual, na apresentação.

## Execução

Instale uma versão compatível do Python e o SWI-Prolog. Extraia o ZIP e abra
um terminal na pasta que contém `etl.py`, `regras.pl` e `consultas.pl`. Não há
dependências Python externas; a biblioteca padrão é suficiente. No Windows,
`py` pode substituir `python` quando esse for o comando disponível.

Execute na ordem:

```text
python --version
swipl --version
python -m unittest -v test_etl.py
python etl.py
swipl -q -s test_regras.pl -g "run_tests,halt"
swipl -q -s consultas.pl
```

O teste Python valida o ETL. `python etl.py` regenera `jogos.pl`,
`limpeza.json` e `conflitos.json`. O comando com `test_regras.pl` executa os
testes Prolog isolados da base real. `consultas.pl` executa e apresenta as
três consultas.

Se `swipl` não for reconhecido, instale o SWI-Prolog, disponibilize o
executável no `PATH` e reabra o terminal. No PowerShell, também é possível
usar o caminho completo correspondente à instalação real:

```powershell
& "C:\Program Files\swipl\bin\swipl.exe" -q -s consultas.pl
```

Testes reprovados aparecem como `FAILED` ou terminam com código diferente de
zero. Testes aprovados aparecem como `passed` e terminam com código zero.
Para salvar as respostas diretamente em UTF-8:

```text
swipl -q -s consultas.pl -g "exportar_resultados('resultados_corrigidos.txt'),halt"
```

O exportador reutiliza a lógica de `consultas.pl` e abre o arquivo com
`encoding(utf8)`. A saída pode ser conferida em um editor que reconheça UTF-8.

## Resultados e validação

O arquivo enviado `resultados.txt` comprova a execução anterior das três
consultas, mas não comprova a bateria de testes Prolog. Essa execução anterior
registrou:

- Pergunta 1: 12 gêneros, 2.323 registros elegíveis e `Sports` com a maior
  discordância média, aproximadamente 13,78 pontos.
- Pergunta 2: 343 registros antes da tolerância, incluindo indevidamente
  `Resident Evil 5` para `PC` por arredondamento.
- Pergunta 3: `The Legend of Zelda: Twilight Princess` com nota conjunta 94
  no GameCube e 92,5 no Wii.

Na versão corrigida, `resultados_corrigidos.txt` contém 342 registros na
pergunta 2, não contém `Resident Evil 5` para `PC`, preserva as respostas das
perguntas 1 e 3 e foi validado como UTF-8.

O ETL regenerado confirmou 16.719 registros lidos, 16.715 fatos mantidos,
duas exclusões por ausência de nome, duas por conflito e zero duplicatas
exatas removidas. Os testes sintéticos Prolog permanecem separados da base
real. A bateria executou efetivamente 21 testes, todos `passed`, com código de
saída 0. A saída completa do comando, incluindo stderr, avisos e eventuais
erros, foi salva em `test_regras.log`; nesta execução não houve erro de teste.
O SWI-Prolog emitiu apenas avisos de singleton/choicepoint já existentes.

## Limitações

A base é um recorte histórico e sua cobertura não representa necessariamente
todo o mercado. Os jogos tiveram tempos diferentes para acumular vendas, e as
avaliações podem apresentar vieses de seleção. Associação entre notas e
vendas não demonstra causalidade.

A base não contém informações suficientes para concluir lucro ou prejuízo,
desempenho técnico, quantidade de bugs ou custo-benefício. O resultado de
“bem avaliado e relativamente pouco vendido” é uma classificação pelos
critérios definidos, não uma medida de qualidade comercial ou causalidade.
