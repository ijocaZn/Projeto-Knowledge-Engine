:- encoding(utf8).
:- use_module(regras).

respostas(Q1, Q2, Q3) :-
    carregar_dados('jogos.pl'),
    discordancia_por_genero(Q1),
    jogos_bem_avaliados(Q2),
    melhores_versoes('The Legend of Zelda: Twilight Princess', Q3).

escrever_respostas(Stream, Q1, Q2, Q3) :-
    format(Stream, 'Q1 discord\u00e2ncia por g\u00eanero:~n~q~n~n', [Q1]),
    format(Stream, 'Q2 bem avaliados e abaixo da mediana:~n~q~n~n', [Q2]),
    format(Stream, 'Q3 vers\u00f5es (todas e melhores):~n~q~n', [Q3]).

exportar_resultados(Arquivo) :-
    respostas(Q1, Q2, Q3),
    setup_call_cleanup(
        open(Arquivo, write, Stream, [encoding(utf8)]),
        escrever_respostas(Stream, Q1, Q2, Q3),
        close(Stream)
    ).

main :-
    respostas(Q1, Q2, Q3),
    current_output(Stream),
    escrever_respostas(Stream, Q1, Q2, Q3).

:- initialization(main, main).
