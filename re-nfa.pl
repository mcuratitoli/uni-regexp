

% --- is_regular_expression(RE) ---

% caso base
is_regular_expression(RE):- 
	atomic(RE), !.
is_regular_expression(RE):- 
	compound(RE), isregex(RE).

% predicato per gestire arietà non fisse di seq e oneof
increaseRE(RE,Max,Max):-
	arg(Max,RE,X), is_regular_expression(X). 
increaseRE(RE,Now,Max):- 
	Now<Max, arg(Now,RE,X), 
	is_regular_expression(X), plus(1,Now,Result), 
	increaseRE(RE,Result,Max).

% passi ricorsivi
isregex(RE):- 
	functor(RE,or,2), arg(1,RE,Arg1), 
	is_regular_expression(Arg1), 
	arg(2,RE,Arg2), 
	is_regular_expression(Arg2), !.
isregex(RE):- 
	functor(RE,star,1), arg(1,RE,Arg), 
	is_regular_expression(Arg), !.
isregex(RE):- 
	functor(RE,bar,1), arg(1,RE,Arg), 
	is_regular_expression(Arg), !.
isregex(RE):- 
	functor(RE,plus,1), arg(1,RE,Arg), 
	is_regular_expression(Arg), !.
isregex(RE):- 
	functor(RE,seq,Ariet), 
	increaseRE(RE,1,Ariet), !.
isregex(RE):- 
	functor(RE,oneof,Ariet), 
	increaseRE(RE,1,Ariet), !.


% --- nfa_re_compile(FA_Id,RE) ---

% nfa_initial(Fa_Id,statoIniziale)
% nfa_delta(Fa_Id,statoDoveSei,conCosaMiSposto,statoDoveVai)
% nfa_final(Fa_Id,statoFinale)

% caso base
nfa_re_compile(FA_Id,RE):-
	atomic(FA_Id), 
	is_regular_expression(RE), 
	gensym(q,QI), gensym(q,QF), 
	assert(nfa_initial(FA_Id,QI)), 
	assert(nfa_final(FA_Id,QF)), 
	RE=..[Func|Args],                           
	nfa_rc(FA_Id,Func,Args,QI,QF), !.

% passi ricorsivi
nfa_rc(FA_Id,Elem,[],QI,QF):- 
	atomic(Elem), 
	assert(nfa_delta(FA_Id,QI,Elem,QF)), !.
nfa_rc(FA_Id,seq,Args,QI,QF):- 
	Args=[H|T], 
	H=..[H1|H2], T\=[], 
	gensym(q,QF1), gensym(q,QI2), 
	nfa_rc(FA_Id,H1,H2,QI,QF1),
	assert(nfa_delta(FA_Id,QF1,epsilon,QI2)), 
	nfa_rc(FA_Id,seq,T,QI2,QF).
nfa_rc(FA_Id,seq,Args,QI,QF):- 
	Args=[H|T], T=[], 
	H=..[H1|H2], 
	gensym(q,QF1),  
	nfa_rc(FA_Id,H1,H2,QI,QF1),
	assert(nfa_delta(FA_Id,QF1,epsilon,QF)) .
nfa_rc(FA_Id,or,Args,QI,QF):- 
	Args=[X,Y], 
	X=..[X1|X2], Y=..[Y1|Y2],
	gensym(q,QI1), gensym(q,QI2), 
	gensym(q,QF1), gensym(q,QF2), 
	assert(nfa_delta(FA_Id,QI,epsilon,QI1)), 
	assert(nfa_delta(FA_Id,QI,epsilon,QI2)),
	nfa_rc(FA_Id,X1,X2,QI1,QF1), 
	nfa_rc(FA_Id,Y1,Y2,QI2,QF2), 
	assert(nfa_delta(FA_Id,QF1,epsilon,QF)), 
	assert(nfa_delta(FA_Id,QF2,epsilon,QF)).

nfa_rc(FA_Id,star,Args,QI,QF):- 
	Args=[H|T], T=[],
	H=..List, List=[X1|X2],  
	gensym(q,QI1), gensym(q,QF1), 
	assert(nfa_delta(FA_Id,QI1,epsilon,QF)), 
	assert(nfa_delta(FA_Id,QI,epsilon,QI1)), 
	nfa_rc(FA_Id,X1,X2,QI1,QF1), 
	assert(nfa_delta(FA_Id,QF1,epsilon,QF)),
	assert(nfa_delta(FA_Id,QF1,epsilon,QI1)).	

nfa_rc(FA_Id,oneof,Args,QI,QF):- 
	Args=[H|T],  T\=[], 
	H=..[H1|H2], 
	gensym(q,QI1), gensym(q,QF1),  
	assert(nfa_delta(FA_Id,QI,epsilon,QI1)), 
	nfa_rc(FA_Id,H1,H2,QI1,QF1), 
	assert(nfa_delta(FA_Id,QF1,epsilon,QF)), 
	nfa_rc(FA_Id,oneof,T,QI,QF).
nfa_rc(FA_Id,oneof,Args,QI,QF):- 
	Args=[H|T], T=[], 
	H=..[H1|H2], 
	gensym(q,QI1), gensym(q,QF1), 
	assert(nfa_delta(FA_Id,QI,epsilon,QI1)), 
	nfa_rc(FA_Id,H1,H2,QI1,QF1), 
	assert(nfa_delta(FA_Id,QF1,epsilon,QF)).

% -- #todo: nfa_rc(FA_Id,bar,Args,QI,QF) --

nfa_rc(FA_Id,plus,Args,QI,QF):- 
	Args=[H|T], T=[],
	H=..List, List=[X1|X2], 
	gensym(q,QI1), gensym(q,QF1), 
	assert(nfa_delta(FA_Id,QI,epsilon,QI1)), 
	nfa_rc(FA_Id,X1,X2,QI1,QF1), 
	assert(nfa_delta(FA_Id,QF1,epsilon,QF)),
	assert(nfa_delta(FA_Id,QF1,epsilon,QI1)).


% --- nfa_recognize(FA_Id,Input) ---

% TO DO: gestire star(star(_)) in modo da evitare
% i loop infiniti;
% si potrebbe passare come parametri in piu lo stato in
% cui si è, e la lista di input in quel momento;
% se capito ancora nello stesso stato con lo stesso input,
% vuol dire che sto per entrare in un loop

% caso base
nfa_recognize(FA_Id,Input):- 
	findall(FA_Id,nfa_initial(FA_Id,_),All_FA_Id), 
	nfa_rcgz_FA_Id_list(FA_Id,All_FA_Id),
 	nfa_initial(FA_Id,I), 
	nfa_rcgz(FA_Id,Input,I). 

nfa_rcgz_FA_Id_list(FA_Id,All_FA_Id):-
	All_FA_Id=[], 
	write('automaton:  -'),  
	write(FA_Id), write('-  not found in db.').
nfa_rcgz_FA_Id_list(FA_Id,All_FA_Id):-
	All_FA_Id=[H|_], 
	H=FA_Id, !.
nfa_rcgz_FA_Id_list(FA_Id,All_FA_Id):-
	All_FA_Id=[H|T], 
	H\=FA_Id, nfa_rcgz_FA_Id_list(FA_Id,T). 

% passi ricorsivi
nfa_rcgz(FA_Id,[H|T],I):-  
	nfa_delta(FA_Id,I,H,F),  
	nfa_rcgz(FA_Id,T,F), !.
nfa_rcgz(FA_Id,[H|T],I):- 
	nfa_delta(FA_Id,I,epsilon,N),   
	nfa_rcgz(FA_Id,[H|T],N), !.
nfa_rcgz(FA_Id,[],N):- 
	nfa_delta(FA_Id,N,epsilon,F), 
	nfa_rcgz(FA_Id,[],F).
nfa_rcgz(FA_Id,[],F):- 
	nfa_final(FA_Id,F).


% --- predicati aggiunti ---

nfa_clear:- 
	retractall(nfa_initial(_,_)), 
	retractall(nfa_final(_,_)),
	retractall(nfa_delta(_,_,_,_)),
	reset_gensym(q),
	write('clear all db.').

nfa_clear_nfa(FA_Id):- 	
	retractall(nfa_initial(FA_Id,_)), 
	retractall(nfa_final(FA_Id,_)),
	retractall(nfa_delta(FA_Id,_,_,_)),
	write('clear all about  -'), 
	write(FA_Id), write('-  .').

nfa_list:- 
	nl, nfa_list_name, nl, !,
	nfa_list(_).

nfa_list(FA_Id):- 
	setof(I,nfa_initial(FA_Id,I),Alli), 
	findall(F,nfa_final(FA_Id,F),Allf), 
	nl, nfa_list_init(FA_Id,Alli), 
	listing(nfa_delta(FA_Id,_,_,_)), 
	nfa_list_fin(FA_Id,Allf).

% per elencare gli nfa_initial del FA_Id selezionato
nfa_list_init(FA_Id,Alli):- 
	Alli=[H|T], H\=[], 
	write('nfa_initial('), 
	write(FA_Id), write(','), 
	write(H), write(')'), 
	nfa_list_init(T).
nfa_list_init(Alli):- 
	Alli=[], nl.

% per elencare gli nfa_final del FA_Id selezionato
nfa_list_fin(FA_Id,Allf):- 
	Allf=[H|T], H\=[], 
	write('nfa_final('), 
	write(FA_Id), write(','), 
	write(H), write(')'), 
	nfa_list_fin(T).
nfa_list_fin(Allf):- 
	Allf=[], nl.

% per elencare solo gli FA_Id degli automi presenti nel db 
nfa_list_name:- 
	findall(FA_Id,nfa_initial(FA_Id,_),All_FA_Id), 
	nfa_list_control(All_FA_Id), !.
nfa_list_control(All_FA_Id):-
	All_FA_Id \= [], 
	write('all automatons id in DB: '), 
 	write(All_FA_Id).
nfa_list_control(All_FA_Id):-
	All_FA_Id = [], 
	write('there are no automatons in DB!').
