:- encoding(utf8).
:- module(regras, [
    jogo/10, carregar_dados/1, limpar_dados/0,
    nota_usuario_100/2, discordancia/3, media/2, mediana/2,
    tolerancia_numerica/1, maior_que_com_tolerancia/2,
    menor_que_com_tolerancia/2,
    elegivel_q1/5, elegivel_q2/5, elegivel_q3/5,
    discordancia_por_genero/6, discordancia_por_genero/1,
    jogos_bem_avaliados/6, jogos_bem_avaliados/1,
    melhores_versoes/6, melhores_versoes/2
]).

:- use_module(library(lists)).
:- dynamic jogo/10.

carregar_dados(Arquivo) :- consult(Arquivo).
limpar_dados :- retractall(jogo(_, _, _, _, _, _, _, _, _, _)).

nota_usuario_100(Nota, Normalizada) :- number(Nota), Normalizada is Nota * 10.

tolerancia_numerica(1.0e-9).

maior_que_com_tolerancia(Valor, Limite) :-
    tolerancia_numerica(Epsilon),
    Valor - Limite > Epsilon.

menor_que_com_tolerancia(Valor, Limite) :-
    tolerancia_numerica(Epsilon),
    Limite - Valor > Epsilon.

discordancia(Critica, Usuario, Valor) :-
    number(Critica), nota_usuario_100(Usuario, Usuario100),
    Valor is abs(Critica - Usuario100).

no_intervalo(Ano, Inicio, Fim) :-
    integer(Ano), Ano >= Inicio, Ano =< Fim.

campo_texto_valido(Valor) :- nonvar(Valor), Valor \= desconhecido.
contagem_valida(Valor, Min) :- integer(Valor), Valor >= Min.
numero_valido(Valor) :- number(Valor), (integer(Valor) ; float(Valor)).
nota_critica_valida(Valor) :- number(Valor), Valor >= 0, Valor =< 100.
nota_usuario_valida(Valor) :- number(Valor), Valor >= 0, Valor =< 10.

elegivel_q1(Jogo, Inicio, Fim, MinCriticos, MinUsuarios) :-
    jogo(N, P, Ano, G, Pub, Vendas, C, QC, U, QU),
    Jogo = jogo(N, P, Ano, G, Pub, Vendas, C, QC, U, QU),
    no_intervalo(Ano, Inicio, Fim), campo_texto_valido(G),
    nota_critica_valida(C), nota_usuario_valida(U), contagem_valida(QC, MinCriticos),
    contagem_valida(QU, MinUsuarios).

elegivel_q2(Jogo, Inicio, Fim, MinCriticos, MinUsuarios) :-
    elegivel_q1(Jogo, Inicio, Fim, MinCriticos, MinUsuarios),
    Jogo = jogo(_, P, _, _, _, V, _, _, _, _),
    campo_texto_valido(P), numero_valido(V), V >= 0.

elegivel_q3(Jogo, Inicio, Fim, MinCriticos, MinUsuarios) :-
    jogo(N, P, Ano, G, Pub, Vendas, C, QC, U, QU),
    Jogo = jogo(N, P, Ano, G, Pub, Vendas, C, QC, U, QU),
    no_intervalo(Ano, Inicio, Fim), campo_texto_valido(P),
    nota_critica_valida(C), nota_usuario_valida(U), contagem_valida(QC, MinCriticos),
    contagem_valida(QU, MinUsuarios).

media([], 0).
media([H|T], Media) :-
    sum_list([H|T], Soma), length([H|T], Quantidade),
    Media is Soma / Quantidade.

mediana([], desconhecida).
mediana(Valores, Mediana) :-
    Valores = [_|_], msort(Valores, Ordenados), length(Ordenados, N),
    ( N mod 2 =:= 1 ->
        I is (N + 1) // 2, nth1(I, Ordenados, Mediana)
    ;   I is N // 2, J is I + 1, nth1(I, Ordenados, A),
        nth1(J, Ordenados, B), Mediana is (A + B) / 2
    ).

discordancia_por_genero(Inicio, Fim, MC, MU, MinGrupo, Resultados) :-
    findall(G, (elegivel_q1(J, Inicio, Fim, MC, MU),
                J = jogo(_, _, _, G, _, _, _, _, _, _)), Gs0),
    sort(Gs0, Gs), findall(R, discordancia_genero(Gs, Inicio, Fim, MC, MU, MinGrupo, R), Rs),
    predsort(comparar_discordancia, Rs, Resultados).

discordancia_por_genero(Resultados) :- discordancia_por_genero(2000, 2016, 10, 50, 20, Resultados).

discordancia_genero([G|Gs], Inicio, Fim, MC, MU, MinGrupo, R) :-
    findall(D, (elegivel_q1(J, Inicio, Fim, MC, MU),
        J = jogo(_, _, _, G, _, _, C, _, U, _), discordancia(C, U, D)), Ds),
    length(Ds, N), N >= MinGrupo,
    findall(S, (elegivel_q1(J2, Inicio, Fim, MC, MU),
        J2 = jogo(_, _, _, G, _, _, C2, _, U2, _),
        nota_usuario_100(U2, U2100), S is C2 - U2100), Ss),
    media(Ds, Abs), media(Ss, Signed), R = resultado(G, N, Abs, Signed).
discordancia_genero([_|Gs], Inicio, Fim, MC, MU, MinGrupo, R) :-
    discordancia_genero(Gs, Inicio, Fim, MC, MU, MinGrupo, R).
discordancia_genero([], _, _, _, _, _, _) :- fail.

comparar_discordancia(Order, resultado(G1, N1, A1, S1), resultado(G2, N2, A2, S2)) :-
    compare(O1, A2, A1), (O1 = (=) -> compare(O2, S2-N2-G2, S1-N1-G1), Order = O2 ; Order = O1).

jogos_bem_avaliados(Inicio, Fim, MC, MU, MinGrupo, Resultados) :-
    findall(G-P, (elegivel_q2(J, Inicio, Fim, MC, MU),
        J = jogo(_, P, _, G, _, _, _, _, _, _)), Grupos0),
    sort(Grupos0, Grupos),
    findall(R, jogo_de_grupo(Grupos, Inicio, Fim, MC, MU, MinGrupo, R), Rs),
    predsort(comparar_jogo, Rs, Resultados).

jogos_bem_avaliados(Resultados) :- jogos_bem_avaliados(2000, 2016, 10, 50, 10, Resultados).

jogo_de_grupo([G-P|Gs], Inicio, Fim, MC, MU, MinGrupo, R) :-
    grupo_stats(Inicio, Fim, MC, MU, MinGrupo, G, P, N, MCrit, MUser, MedV),
    elegivel_q2(J, Inicio, Fim, MC, MU),
    J = jogo(Nome, P, _, G, Pub, V, C, _, U, _),
    maior_que_com_tolerancia(C, MCrit),
    maior_que_com_tolerancia(U, MUser),
    menor_que_com_tolerancia(V, MedV),
    R = resultado(Nome, P, Pub, C, U, V, N, MCrit, MUser, MedV).
jogo_de_grupo([_|Gs], Inicio, Fim, MC, MU, MinGrupo, R) :-
    jogo_de_grupo(Gs, Inicio, Fim, MC, MU, MinGrupo, R).

grupo_stats(Inicio, Fim, MC, MU, MinGrupo, G, P, N, MCrit, MUser, MedV) :-
    findall(C, (elegivel_q2(J, Inicio, Fim, MC, MU),
        J = jogo(_, P, _, G, _, _, C, _, _, _)), Cs),
    findall(U, (elegivel_q2(J2, Inicio, Fim, MC, MU),
        J2 = jogo(_, P, _, G, _, _, _, _, U, _)), Us),
    findall(V, (elegivel_q2(J3, Inicio, Fim, MC, MU),
        J3 = jogo(_, P, _, G, _, V, _, _, _, _)), Vs),
    length(Cs, N), N >= MinGrupo, media(Cs, MCrit), media(Us, MUser), mediana(Vs, MedV).

comparar_jogo(Order, resultado(N1, P1, Pub1, C1, U1, V1, G1, MC1, MU1, MV1),
               resultado(N2, P2, Pub2, C2, U2, V2, G2, MC2, MU2, MV2)) :-
    compare(O1, N1-P1-Pub1-C1-U1-V1-G1-MC1-MU1-MV1,
               N2-P2-Pub2-C2-U2-V2-G2-MC2-MU2-MV2),
    Order = O1.

melhores_versoes(Nome, Inicio, Fim, MC, MU, Resposta) :-
    findall(V, versao_valida(Nome, Inicio, Fim, MC, MU, V), Versoes),
    findall(P, member(versao(P, _, _, _, _, _, _), Versoes), Ps), sort(Ps, Unicas),
    ( Unicas = [_,_|_] ->
        predsort(comparar_versao, Versoes, Ordenadas),
        Ordenadas = [versao(_, _, _, _, _, _, Melhor)|_],
        include(mesma_nota(Melhor), Ordenadas, Melhores),
        Resposta = versoes(Ordenadas, Melhores)
    ; Resposta = comparacao_insuficiente
    ).

melhores_versoes(Nome, Resposta) :- melhores_versoes(Nome, 2000, 2016, 10, 50, Resposta).

versao_valida(Nome, Inicio, Fim, MC, MU, V) :-
    elegivel_q3(J, Inicio, Fim, MC, MU),
    J = jogo(Nome, P, Ano, _, _, _, C, QC, U, QU),
    nota_usuario_100(U, U100), Score is (C + U100) / 2,
    V = versao(P, Ano, C, QC, U, QU, Score).

comparar_versao(Order, versao(P1, A1, C1, QC1, U1, QU1, S1),
                versao(P2, A2, C2, QC2, U2, QU2, S2)) :-
    compare(O1, S2, S1),
    (O1 = (=) -> compare(Order, P1-A1-C1-QC1-U1-QU1, P2-A2-C2-QC2-U2-QU2) ; Order = O1).

mesma_nota(Nota, versao(_, _, _, _, _, _, Outra)) :-
    Outra =:= Nota.
