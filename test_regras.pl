:- encoding(utf8).
:- begin_tests(regras).

:- use_module(regras).

test(normalizacao_e_discordancia) :-
    nota_usuario_100(8.5, Usuario100),
    discordancia(90, 8.5, Discordancia),
    assertion(Usuario100 =:= 85),
    assertion(Discordancia =:= 5).
test(mediana_impar) :-
    mediana([3, 1, 2], Mediana),
    assertion(Mediana =:= 2).
test(mediana_par_com_repeticao) :-
    mediana([1, 1, 1, 9], Mediana),
    assertion(Mediana =:= 1).
test(media_vazia) :-
    media([], Media),
    assertion(Media =:= 0).

test(tolerancia_reproducao_71) :-
    QuaseMediana is 10 - 0.5e-9,
    \+ maior_que_com_tolerancia(7.1, 7.099999999999999),
    \+ menor_que_com_tolerancia(QuaseMediana, 10),
    menor_que_com_tolerancia(1, 10),
    assertion(7.1 - 7.099999999999999 < 1.0e-9).

test(nota_igual_media_nao_aceita, [setup(grupo_nota_igual_media), cleanup(limpar_dados)]) :-
    regras:grupo_stats(2000, 2000, 10, 50, 3, 'Action', p1,
                       N, MediaCritica, MediaUsuario, MedianaVendas),
    assertion(N =:= 3),
    assertion(MediaCritica =:= 80),
    assertion(MediaUsuario =:= 8),
    assertion(MedianaVendas =:= 10),
    jogos_bem_avaliados(2000, 2000, 10, 50, 3, Resultados),
    \+ member(resultado('NotaIgualMedia', _, _, _, _, _, _, _, _, _), Resultados).

test(nota_abaixo_da_tolerancia_nao_aceita, [setup(grupo_nota_quase_media), cleanup(limpar_dados)]) :-
    regras:grupo_stats(2000, 2000, 10, 50, 3, 'Action', p1,
                       _, MediaCritica, MediaUsuario, MedianaVendas),
    jogo('NotaQuaseMedia', p1, 2000, 'Action', pub, Vendas,
         NotaCandidato, _, UsuarioCandidato, _),
    NotaDiferenca is NotaCandidato - MediaCritica,
    assertion(NotaDiferenca > 0),
    assertion(NotaDiferenca < 1.0e-9),
    assertion(UsuarioCandidato - MediaUsuario > 1.0e-9),
    assertion(MedianaVendas - Vendas > 1.0e-9),
    jogos_bem_avaliados(2000, 2000, 10, 50, 3, Resultados),
    \+ member(resultado('NotaQuaseMedia', _, _, _, _, _, _, _, _, _), Resultados).

test(nota_acima_da_tolerancia_aceita, [setup(grupo_nota_acima_tolerancia), cleanup(limpar_dados)]) :-
    jogos_bem_avaliados(2000, 2000, 10, 50, 3, Resultados),
    member(resultado('NotaAcimaTolerancia', p1, _, _, _, _, _, _, _, _), Resultados).

test(vendas_iguais_mediana_nao_aceitas, [setup(grupo_vendas_quase_mediana), cleanup(limpar_dados)]) :-
    jogos_bem_avaliados(2000, 2000, 10, 50, 3, Resultados),
    \+ member(resultado('VendasIguaisMediana', _, _, _, _, _, _, _, _, _), Resultados).

test(vendas_quase_mediana_nao_aceitas, [setup(grupo_vendas_quase_mediana), cleanup(limpar_dados)]) :-
    regras:grupo_stats(2000, 2000, 10, 50, 3, 'Action', p1,
                       _, MediaCritica, MediaUsuario, MedianaVendas),
    jogo('VendasQuaseMediana', p1, 2000, 'Action', pub, Vendas,
         NotaCandidato, _, UsuarioCandidato, _),
    VendaDiferenca is MedianaVendas - Vendas,
    assertion(NotaCandidato - MediaCritica > 1.0e-9),
    assertion(UsuarioCandidato - MediaUsuario > 1.0e-9),
    assertion(VendaDiferenca > 0),
    assertion(VendaDiferenca < 1.0e-9),
    jogos_bem_avaliados(2000, 2000, 10, 50, 3, Resultados),
    \+ member(resultado('VendasQuaseMediana', _, _, _, _, _, _, _, _, _), Resultados).

test(caso_completo_selecionado, [setup(grupo_nota_acima_tolerancia), cleanup(limpar_dados)]) :-
    jogos_bem_avaliados(2000, 2000, 10, 50, 3, Resultados),
    member(resultado('Completo', p1, _, 81, 9, 2, 4, _, _, _), Resultados).

test(nota_ausente, [setup(nota_ausente), cleanup(limpar_dados), fail]) :-
    elegivel_q1(jogo('synthetic-missing-score', _, _, _, _, _, desconhecido, _, 8, 100),
                2000, 2000, 10, 50).

test(minimos_exatos_e_abaixo, [setup(base_minima), cleanup(limpar_dados)]) :-
    assertz(jogo('Limite', p1, 2000, 'Action', pub, 1, 80, 10, 8, 50)),
    elegivel_q1(jogo('Limite', p1, 2000, 'Action', pub, 1, 80, 10, 8, 50), 2000, 2000, 10, 50),
    retract(jogo('Limite', p1, 2000, 'Action', pub, 1, 80, 10, 8, 50)),
    assertz(jogo('AbaixoCriticos', p1, 2000, 'Action', pub, 1, 80, 9, 8, 50)),
    \+ elegivel_q1(_, 2000, 2000, 10, 50),
    retractall(jogo(_, _, _, _, _, _, _, _, _, _)),
    assertz(jogo('AbaixoUsuarios', p1, 2000, 'Action', pub, 1, 80, 10, 8, 49)),
    \+ elegivel_q1(_, 2000, 2000, 10, 50).

test(agrupamento_sem_mistura, [setup(base_minima), cleanup(limpar_dados)]) :-
    assertz(jogo('A', p1, 2000, 'Action', pub, 1, 80, 10, 8, 50)),
    assertz(jogo('B', p1, 2000, 'Puzzle', pub, 1, 90, 10, 7, 50)),
    discordancia_por_genero(2000, 2000, 10, 50, 1,
                            [resultado('Puzzle', 1, PuzzleAbs, PuzzleSigned),
                             resultado('Action', 1, ActionAbs, ActionSigned)]),
    assertion(PuzzleAbs =:= 20),
    assertion(PuzzleSigned =:= 20),
    assertion(ActionAbs =:= 0),
    assertion(ActionSigned =:= 0).

test(tamanho_grupo_abaixo_do_minimo, [setup(grupo_nove), cleanup(limpar_dados)]) :-
    jogos_bem_avaliados(2000, 2000, 10, 50, 10, []).

test(tamanho_grupo_no_minimo, [setup(grupo_dez), cleanup(limpar_dados)]) :-
    jogos_bem_avaliados(2000, 2000, 10, 50, 10, Resultados),
    member(resultado('Positivo', p1, _, _, _, 1, 10, _, _, MedianaVendas), Resultados),
    assertion(MedianaVendas =:= 10),
    \+ member(resultado('FalhaCritica', _, _, _, _, _, _, _, _, _), Resultados),
    \+ member(resultado('FalhaUsuario', _, _, _, _, _, _, _, _, _), Resultados),
    \+ member(resultado('FalhaVendas', _, _, _, _, _, _, _, _, _), Resultados).

test(vendas_ausentes_por_pergunta, [setup(venda_ausente), cleanup(limpar_dados)]) :-
    elegivel_q1(jogo('SemVendas', _, _, _, _, _, _, _, _, _),
                2000, 2000, 10, 50),
    elegivel_q3(jogo('SemVendas', _, _, _, _, _, _, _, _, _),
                2000, 2000, 10, 50),
    \+ elegivel_q2(jogo('SemVendas', _, _, _, _, _, _, _, _, _),
                  2000, 2000, 10, 50).

test(versao_vencedora_unica, [setup(versoes), cleanup(limpar_dados)]) :-
    melhores_versoes('Unico', 2000, 2000, 10, 50,
                     versoes(Ordenadas, Melhores)),
    Ordenadas = [versao(p2, _, _, _, _, _, NotaP2),
                 versao(p1, _, _, _, _, _, NotaP1)],
    Melhores = [versao(p2, _, _, _, _, _, Melhor)],
    assertion(NotaP2 =:= 90),
    assertion(NotaP1 =:= 80),
    assertion(Melhor =:= 90).

test(versoes_empatadas, [setup(versoes), cleanup(limpar_dados)]) :-
    melhores_versoes('Empate', 2000, 2000, 10, 50,
                     versoes(Ordenadas, Melhores)),
    Ordenadas = [versao(p2, _, CriticaP2, _, UsuarioP2, _, NotaP2),
                 versao(p3, _, CriticaP3, _, UsuarioP3, _, NotaP3),
                 versao(p1, _, CriticaP1, _, UsuarioP1, _, NotaP1)],
    Melhores = [versao(p2, _, _, _, _, _, MelhorP2),
                versao(p3, _, _, _, _, _, MelhorP3)],
    assertion(CriticaP2 =:= 90),
    assertion(UsuarioP2 =:= 8),
    assertion(CriticaP3 =:= 80),
    assertion(UsuarioP3 =:= 9),
    assertion(CriticaP1 =:= 80),
    assertion(UsuarioP1 =:= 8),
    assertion(NotaP2 =:= 85),
    assertion(NotaP3 =:= 85),
    assertion(NotaP1 =:= 80),
    assertion(MelhorP2 =:= 85),
    assertion(MelhorP3 =:= 85).

test(plataformas_insuficientes, [setup(base_minima), cleanup(limpar_dados)]) :-
    assertz(jogo('Uma', p1, 2000, 'Action', pub, 1, 80, 10, 8, 50)),
    melhores_versoes('Uma', 2000, 2000, 10, 50, comparacao_insuficiente).

test(consultas_sem_resultados, [setup(base_minima), cleanup(limpar_dados)]) :-
    discordancia_por_genero(1900, 1901, 10, 50, 1, []),
    jogos_bem_avaliados(1900, 1901, 10, 50, 1, []),
    melhores_versoes('Inexistente', 2000, 2000, 10, 50,
                     comparacao_insuficiente).

base_minima :- limpar_dados.

nota_ausente :-
    limpar_dados,
    assertz(jogo('synthetic-missing-score', p1, 2000, 'Action', pub,
                 1, desconhecido, 10, 8, 100)).

grupo_nove :-
    limpar_dados,
    forall(between(1, 9, I),
           assertz(jogo(I, p1, 2000, 'Action', pub, 10, 70, 10, 7, 50))).

grupo_dez :-
    limpar_dados,
    assertz(jogo('Positivo', p1, 2000, 'Action', pub, 1, 90, 10, 9, 50)),
    assertz(jogo('FalhaCritica', p1, 2000, 'Action', pub, 1, 60, 10, 9, 50)),
    assertz(jogo('FalhaUsuario', p1, 2000, 'Action', pub, 1, 90, 10, 6, 50)),
    assertz(jogo('FalhaVendas', p1, 2000, 'Action', pub, 20, 90, 10, 9, 50)),
    forall(between(1, 6, I),
           assertz(jogo(I, p1, 2000, 'Action', pub, 10, 70, 10, 7, 50))).

venda_ausente :-
    limpar_dados,
    assertz(jogo('SemVendas', p1, 2000, 'Action', pub, desconhecido, 80, 10, 8, 50)),
    assertz(jogo('ComVendas', p2, 2000, 'Action', pub, 1, 80, 10, 8, 50)).

versoes :-
    limpar_dados,
    assertz(jogo('Unico', p1, 2000, 'Action', pub, 1, 80, 10, 8, 50)),
    assertz(jogo('Unico', p2, 2000, 'Action', pub, 1, 90, 10, 9, 50)),
    assertz(jogo('Empate', p1, 2000, 'Action', pub, 1, 80, 10, 8, 50)),
    assertz(jogo('Empate', p2, 2000, 'Action', pub, 1, 90, 10, 8, 50)),
    assertz(jogo('Empate', p3, 2000, 'Action', pub, 1, 80, 10, 9, 50)).

grupo_nota_igual_media :-
    limpar_dados,
    assertz(jogo('NotaIgualMedia', p1, 2000, 'Action', pub, 7, 80, 10, 9, 50)),
    assertz(jogo('ParA', p1, 2000, 'Action', pub, 10, 70, 10, 7, 50)),
    assertz(jogo('ParB', p1, 2000, 'Action', pub, 13, 90, 10, 8, 50)).

grupo_nota_quase_media :-
    limpar_dados,
    NotaCandidato is 80 + 0.5e-9,
    assertz(jogo('NotaQuaseMedia', p1, 2000, 'Action', pub, 7, NotaCandidato, 10, 9, 50)),
    assertz(jogo('ParA', p1, 2000, 'Action', pub, 10, 70, 10, 7, 50)),
    assertz(jogo('ParB', p1, 2000, 'Action', pub, 13, 90, 10, 8, 50)).

grupo_nota_acima_tolerancia :-
    limpar_dados,
    assertz(jogo('NotaAcimaTolerancia', p1, 2000, 'Action', pub, 1, 82, 10, 9, 50)),
    assertz(jogo('ParA', p1, 2000, 'Action', pub, 10, 70, 10, 7, 50)),
    assertz(jogo('ParB', p1, 2000, 'Action', pub, 13, 90, 10, 8, 50)),
    assertz(jogo('Completo', p1, 2000, 'Action', pub, 2, 81, 10, 9, 50)).

grupo_vendas_quase_mediana :-
    limpar_dados,
    VendasQuaseMediana is 10 - 0.5e-9,
    assertz(jogo('VendasQuaseMediana', p1, 2000, 'Action', pub,
                 VendasQuaseMediana, 90, 10, 9, 50)),
    assertz(jogo('ParA', p1, 2000, 'Action', pub, 10, 70, 10, 7, 50)),
    assertz(jogo('ParB', p1, 2000, 'Action', pub, 11, 80, 10, 8, 50)),
    assertz(jogo('VendasIguaisMediana', p1, 2000, 'Action', pub,
                 10, 90, 10, 9, 50)).

:- end_tests(regras).
