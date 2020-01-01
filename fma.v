From Coq Require Import ssreflect ssrfun ssrbool.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Require Import Coq.Program.Equality.

Require Import Arith_base.
Require Import Vectors.Fin.
Require Import Vectors.VectorDef.

Class Lex (A : Set) (FCross : A -> A -> A) (Cp : A -> A -> bool) : Prop := {
    transformable : forall (x : A), {P | x <> P x};
    anti_identity : forall (x y : A), x <> y -> x <> FCross x y;
    convergent_equality : forall (x y : A), Cp x y = true -> x = y;
    identity : forall (y : A), {x | (Cp x y = false) -> FCross x y = y}
}.

Class Agent {A : Set} {f : A -> A -> A} {f'} (H : Lex f f') (T : Set) := {
 memory : T -> A
}.

Section Env.
Variables X B A : Set.
Variable f : X -> X -> X.
Variable f' : X -> X -> bool.
Variable K : Lex f f'.
Variable H : Set -> Set.
Variable C : H A -> B -> Prop.
Variable point : forall x y , C x y -> A.
Variable Perception : forall {x y : B} (k : H A), C k x -> C k y -> bool.
Variable Action : forall {x y : B} (k : H A) (x' : C k x) (y' : C k y), H A -> Prop.
Variable AG : Agent K A.

Record Functions : Type := F' {
   faction : H A -> H A;
   flang : H A -> H A
}.

Record Interation {x y} k (x' : C k x) (y' : C k y) (P : Functions) : Prop := I' {
    consistency_action : forall (H' : Perception x' y' = true),
                Action x' y' ((faction P) k);

    knowlegde : forall (a : C ((flang P) k) x)  (H' : Perception x' y' = true),
         memory (point a)  = (f (memory (point x')) (memory ((point y'))))
  
}.

Class Environment := {
  inhabited : forall (x : H A), {b | C x b};
  iterate : forall {x y : B} (k : H A) (x' : C k x) (y' : C k y), {H | Interation x' y' H}; 

}.

End Env.

Inductive binary := |zero : binary |one : binary.

Inductive lex n := 
|lex' : t binary (S n) -> lex n.

Fixpoint invert_binary {y} (x : t binary y) : t binary y.
induction x.
refine (nil _).
destruct h.
refine (cons _ one _ (invert_binary _ x)).
refine (cons _ zero _ (invert_binary _ x)).
Defined.

Theorem _not_conservation: 
  forall n (x : lex n), {P : forall {n} {h : lex n}, lex n | x <> P n x}.
move => x'.
pose (fun y (x : lex y) => 
  match x with
    |@lex' _ v  => @lex' y (invert_binary v)
  end).
intros; exists l.
destruct x; simpl; injection; intros.
clear H.
move : H0.
elim/@caseS' : t.
intros.
destruct h.
inversion H0.
inversion H0.
Qed.


Export VectorNotations.

Definition case1 {A} (P : t A 1 -> Type)
  (H : forall h, @P [h]) (v: t A 1) : P v :=
match v with
  |h :: t => match t with
    |nil _ => H h
  end
  |_ => fun devil => False_ind (@IDProp) devil 
end.

Definition case_2nat (P : nat -> nat -> Type) 
  (H : P 0 0) (H' : forall y, P 0 (S y)) (H1 : forall x, P (S x) 0) 
     (H2 : forall x y, P (S x) (S y))
   : forall x y, P x y.
move => x y.
destruct x.
destruct y.
exact H.
refine (H' y).
destruct y.
refine (H1 x).
refine (H2 x y).
Defined.


Definition rect_SS' {A} (P : forall n, t A (S n) -> Type)
  (H : forall n h a (t : t A (S n)), P _ t -> P _ (a :: h :: t)) (H' : forall h, @P 0 [h]) (H1' : forall h v, @P 1 [h; v]) : forall n (x : t A (S n)), P _ x. 
  
  refine (fix fix_S n (v : t A (S n)) {struct v} : P n v := _).
  refine (match v as c in (t _ (S n)) return P n c with
  |cons _ h 0 v' => match v' with
      |@nil _ => _
    end
  | cons _ h 1 v1 => _
  | cons _ a (S (S n')) v' => _
  | _ => fun devil => False_rect (@IDProp) devil
  end).

intros.
refine (H' h).
intros.
refine (match v1 with
  |@cons _ k 0 q => match q in (t _ 0) with
    |@nil _ => _ 
  end
 end).

refine (H1' h k).
refine (match v' as c in (t _ (S (S n'))) return P (S (S n')) (a :: c) with
  |@cons _ k n q => _
 end).

destruct n.
exact idProp.
refine (H _ k a _ (fix_S _ q)).

Defined.


Definition rect_2S {A B} (P:forall {n}, t A (S n) -> t B (S n) -> Type)
  (bas : forall x y, P [x] [y]) (rect : forall {n} (v1 : t A (S n)) (v2 : t B (S n)), P v1 v2 ->
    forall a b, P (a :: v1) (b :: v2)) : 
     forall {n} (v1 : t A (S n)) (v2 : t B (S n)), P v1 v2.

  refine (fix rect2_fix {n} (v1 : t A (S n)) : forall v2 : t B (S n), P _ v1 v2 :=
  match v1 in t _ (S n) with
  | [] => idProp
  | @cons _ h1 (S n') t1 => fun v2 =>
    caseS' v2 (fun v2' => P _ (h1::t1) v2') (fun h2 t2 => rect _ _ _ (rect2_fix t1 t2) h1 h2)
  |cons _ a 0 x' => fun (v2 : t B 1) => _ 
 end).

elim/@case0 : x'.
refine (match v2 with
  |cons _ b 0 y' => match y' with
      |nil _ => _
      |_ => _
    end
  end).

elim/@case0 : y'.
refine (bas a b).
exact idProp.
Defined.

(*
Definition rect2_binary_lex (P : forall n, t binary n -> t binary n -> Type)
 (base : forall (h h' : binary), P _ (cons _ h 0 (nil _)) (cons _ h' 0 (nil _)))
 (H' : forall (h h' : binary) (n1 : nat) t t0, P (S n1) t t0 -> P _ (cons _ h _ t) (cons _ h' _ t0))
 :
 forall n (x : t binary (S n)) (y : t binary (S n)), P _ x y.

 refine (fix rectS_fix {n} (v: t binary (S n)) {struct v} := _).
 intros.
 have : ((fun a n (x : t a n) => match x with 
       |cons _ _ n _ => (S n)
       |nil _ => 0
     end) _ _ v >= 1
 ).
 elim/@caseS : v.
 intros.
 auto with arith.
 move => H1'.

 elim/@rect2 : v/y.
 intros.
   have : ~ 0 >= 1.
   move => f'.
   inversion f'.
 tauto.
 intros; destruct n0; clear X.
 elim/@case0 : v1.
 elim/@case0 : v2.
 refine (base a b).
 refine (H' a b _ _ _ (rectS_fix _ v1 v2)).
Defined.
*)

Fixpoint cross_binary_vector {n} (x : t binary (S n)) (y : t binary (S n)) : t binary (S n).
elim/@rect_2S  : x/y.
intros.
refine (cons _ y _ (nil _)).
intros.

refine (match (a, b) with
  |(one, one) => (cons _ a _ (cross_binary_vector _ v1 v2))
  |(zero, zero) => (cons _ a _ (cross_binary_vector _ v1 v2))
  |(x', y') => (cons _ b _ v1)
 end).

Defined.


Definition cross_lex {n} (x : lex n) (y : lex n) : lex n.
constructor.
destruct x.
destruct y.
refine (cross_binary_vector t t0).
Defined.


Definition b_rect (P : binary -> binary -> Type) (H : P one one) (H' : P zero zero) (H1' : P one zero) (H2' : P zero one) (x y : binary) : P x y. 
intros.
destruct x.
destruct y.
move => //=.
move => //=.
destruct y.
move => //=.
move => //=.
Defined.

Theorem crossover_binary : 
  forall   n
           (x : t binary (S n))
           (y : t binary (S n)),
           x <> y ->
           x <> cross_binary_vector x y.

  have : forall t t0, lex' t <> lex' t0 -> t <> t0.
  intros.
  cbv in H.
  cbv.
  move => h'.
    have : lex' t = lex' t0.
    congruence.
  tauto.

  have : forall n h x y, cons _ n h x <> cons _ n h y -> x <> y.
   intros.
   move => H'.
   congruence.
  move => H'.

  have : forall h n x y, x <> y -> cons _ n h x <> cons _ n h y.
   intros. 
   move => H2'.
   pose (fun a n (x : t a (S n)) => match x in (t _ (S n)) with
     |@cons _ _ _ x => x
     end).
   pose (@f_equal (t T (S h)) (t T h) (@y0 _ _) _ _ H2').
   simpl in e.
   tauto.
 move => K.

intros.
move : H; elim/@rect_2S : y/x0.
intros; unfold cross_binary_vector; simpl in *.
auto.
intros; move : H0 H; elim/@b_rect : a/b.
intros.
unfold cross_binary_vector; simpl; fold @cross_binary_vector.
apply H' in H0; apply H in H0.
auto.
intros.
unfold cross_binary_vector; simpl; fold @cross_binary_vector.
apply H' in H0; apply H in H0;apply : K.
trivial.
intros.
unfold cross_binary_vector; simpl; fold @cross_binary_vector.
move => H2'.
inversion H2'.
intros.
unfold cross_binary_vector; simpl; fold @cross_binary_vector.
move => H2';inversion H2'.
Qed.

Definition eq_vector_binary : forall (n : nat), t binary (S n) -> t binary (S n) -> bool.
  pose (fun (x y : binary) => match (x, y) with
  |(one, one) => true
  |(zero, zero) => true
  |(x, y) => false
  end).
  
  refine (fix fix_S n (t t0 : t binary (S n)) {struct t} := _).
  elim/@rect_2S : t/t0.
  intros;refine (b x y).
  intros;refine ((b a b0) && (fix_S _ v1 v2)).
Defined.

Definition lex_binary : forall (n : nat), lex n -> lex n -> bool.
intros.
destruct H.
destruct H0.
refine (eq_vector_binary t t0).
Defined.

Theorem lex_eq : forall n (v y : lex n), lex_binary v y = true -> v = y.
intros.
destruct v. destruct y.
move : H.
elim/@rect_2S : t/t0.
move => x y.
elim/b_rect : x/y.
trivial.
trivial.
simpl in *; congruence.
simpl in *; congruence.
intros.
move : H0.
elim/b_rect : a/b.
 - intros; simpl in *; apply H in H0; congruence.
 - intros; simpl in *; apply H in H0; congruence.
 - intros; simpl in *; congruence.
 - intros; simpl in *; congruence.
Qed.


Fixpoint imperfect_binary_cpy {n} (x : t binary (S n)) : t binary (S n).
elim/@rectS : x.
case.
exact (cons _ one _ (nil _)).
exact (cons _ zero _ (nil _)).
intros.
refine (cons _ a _ (imperfect_binary_cpy _ v)).
Defined.

Theorem unique_binary_object_convergent_complement {n} (y : t binary (S n)) :
   {x | x <> y -> cross_binary_vector x y = y}.
exists (imperfect_binary_cpy y).
move : y; elim/@rectS.
case => //=.
case => //= H' V hi h.
have : imperfect_binary_cpy V <> V.
congruence.
move => H.
have : cross_binary_vector (imperfect_binary_cpy V) V = V.
apply : hi H; move => H3.
congruence.
have : imperfect_binary_cpy V <> V.
congruence.
move => H.
have : cross_binary_vector (imperfect_binary_cpy V) V = V.
apply : hi H; move => H3.
congruence.
Qed.


Theorem neg_of_convergent_lex : forall n (x : lex n) y, lex_binary x y = false -> x <> y.

  have : forall x y, lex_binary x y = false -> ~ lex_binary x y = true.
  move => n0 x0 y0.
  destruct (lex_binary x0 y0).
  move => h2.
  inversion h2.
  move => H2 H3.
  inversion H3.

intros.
apply x in H.
move => H2.
destruct x0.
destruct y.
move : H2 H.
elim/@rect_2S : t/t0.
move => x0 y.
elim/@b_rect : x0/y.
auto.
auto.
intros; inversion H2.
intros; inversion H2.
move => n0 v1 v2 H a b.

pose (fun n (x : t binary (S n)) => match x in t _ (S n) with
  |a :: b => b
 end).

elim/@b_rect : a/b.
intros.
simpl in *.
  have : one :: v1 = one :: v2.
  congruence.
move => e'.
apply (@f_equal _ _ (@y (S n0))) in e'; simpl in e'.
  have : lex' v1 = lex' v2.
  congruence.
auto.
intros.
simpl in *.
  have : zero :: v1 = zero :: v2.
  congruence.
move => e'.
apply (@f_equal _ _ (@y (S n0))) in e'; simpl in e'.
  have : lex' v1 = lex' v2.
  congruence.
auto.
intros.
inversion H2.
intros.
inversion H2.
Qed.

Instance binary_lex : forall x, Lex (@cross_lex x) (@lex_binary x).
 {
 
  constructor.

  (* The proof of lex transform *)
  intros.
  pose (_not_conservation x0).
  destruct s.
  exists (x1 x).
  trivial.
  
  (*Anti-identity proof of crossover function *)
  intros.
  destruct x0.
  destruct y.
    have : t <> t0. 
    congruence.
  intros.
  unfold cross_lex.
  injection.
  exact (crossover_binary x0).

  (*Convergence implies to definitional equality *)
  intros.
  exact (lex_eq H).

  (*Existence of Convergence aproximation from x to y*)
  intros.
  destruct y.
  destruct (unique_binary_object_convergent_complement t).
  exists (lex' x0).
  move => H'.
    have : x0 <> t.
    set (neg_of_convergent_lex H'); congruence.
  move => H.
  apply e in H.
  unfold cross_lex.
  congruence.
}
Defined.

Inductive SAgent n :=
   T' : lex n -> SAgent n.

Definition agent_lex {n} (x : SAgent n) := 
  match x with
    |@T' _ l => l
 end.

Fixpoint len {a} {n} (x : t a n) :=
  match x with
    |_ :: y => (len y) + 1
    |[] => 0
  end.


(*The class Agent is just a proof that there is a depedent product of a lex
  and one construction and the depedent product carry a memory that map the construction
   with one lexical memory *)

Instance SAgent' : forall x, Agent (binary_lex x) (SAgent x). {
  constructor.
  refine (@agent_lex x).
}
Defined.

Require Import Coq.Init.Specif.

Definition get_agent {n} {l} (ls : t (SAgent n) l) (y : nat) (H : y < l) : SAgent n := nth_order ls H.

Definition boundness {n} {l} (ls : t (SAgent n) l) (y : nat) : Prop := y < l.

Definition view {l} {n} {y} {y'} (v : t (SAgent n) (S l)) (H : y < (S l)) (H' : y' < (S l)) := 
  (y =? 0) && (y' =? l).

Definition match_lex {l} {n} (v : t (SAgent n) (S l)) : t (SAgent n) (S l).

  have : 0 < S l /\ l < S l.
  auto with arith.
move => h.
destruct h.
set f' := v[@of_nat_lt H].
set s' := v[@of_nat_lt H0].

refine (replace (replace v (of_nat_lt H0) (T' (cross_lex (memory s') (memory f')))) 
  (of_nat_lt H) (T' (cross_lex (memory f') (memory s')))).
Defined.

Definition action_prop {l} {n} {y} {y'} (v : t (SAgent n) (S l)) (H : y < S l) (H' : y' < S l) : t (SAgent n) (S l) -> Prop.
move => v'.
refine (get_agent v H = get_agent v' H').
Defined.

Definition tail := (fun a n (v : t a (S n))  => match v in (t _ (S n)) with
   |@cons _ _ _ v' => v'
   |@nil _ => idProp
 end).

Theorem head_get : forall a n (x : t a (S n)) (H : 0 < (S n)), hd x = nth x (Fin.of_nat_lt H).
intros.
move : H.
by elim/@caseS : x.
Qed.

Theorem last_tail : forall a n (x : t a (S n)) (H : n < (S n)), last x = nth x (Fin.of_nat_lt H).
intros.
move : H.
elim/@rectS : x.
intros.
by simpl.
intros.
simpl in *.
generalize (lt_S_n n0 (S n0) H0).
move => t.
pose (H t).
trivial.
Qed.

Theorem shift_hd_get' : forall A n (x : t A (S n)) (H : n < (S n)) (a : A), (shiftin a x)[@FS (Fin.of_nat_lt H)] = a.
intros.
move : H.
elim/@rect_SS' : x.
intros.
simpl in *.
by set (H (lt_S_n n0 (S n0)
                       (lt_S_n (S n0) 
                          (S (S n0)) H0))).
trivial.
intros.
simpl in *.
trivial.
Defined.

Theorem of_nat_lt_c : forall x y (v : x < y) (v' : x < y), of_nat_lt v = of_nat_lt v'.
move => x y.
elim/@nat_double_ind : x/y.
intros.
destruct n.
inversion v.
simpl in *; trivial.
intros;inversion v.
intros.
set (H (lt_S_n n m v) (lt_S_n n m v')); simpl in *; rewrite e.
reflexivity.
Qed.

Definition shift {l} {n} (v : t (SAgent n) (S l)) : t (SAgent n) (S l).
destruct l.
exact v.
destruct l.
refine (cons _ (hd (tail v)) _ (cons _ (hd v) _ (nil _))).
refine (shiftin (hd v) (tail v)).
Defined.


(*Definition rect3S {A} (P : forall n, t A (S n) -> Prop) (H : forall x, P [x]) (H' : forall x y, P [x; y])
   (H1' : forall n (v : t A , *)

Require Import Coq.Bool.Bool.

Compute get_agent.

Instance SEnvironment : forall x y,
   @Environment _ _ _ _ _ _ (fun x => t x (S y)) boundness get_agent (@view _ _) (@action_prop _ _) (SAgent' x).
{
  constructor.
  exists 0.
  elim/@caseS : x0.
  unfold boundness.
  auto with arith.
  intros.
  exists (F' shift match_lex).
  constructor;intros.
  unfold view in H'.
  unfold action_prop.
  intros.
  unfold boundness in *.
  move : H' x' y' k.
  elim/@case_2nat : x0/y0.
  intros.
  destruct y.
  simpl in *.
  trivial.
  move : H' y' x'.
  intros; simpl; inversion H'.
  intros.
  trivial.
  intros;inversion H'.
  intros;inversion H'.
  apply andb_true_iff in H'.
  destruct H'.
  apply beq_nat_true in H2.
  subst.
  move : y' x' H H1.
  elim/@rect_SS' : k.
  intros; simpl in *.
  unfold get_agent; unfold nth_order.
  simpl in *; symmetry.
  pose(shift_hd_get' t (lt_S_n n (S n) (lt_S_n (S n) (S (S n)) y')) a).
  done.
  done.
  done.
  done.
  done.
  
  simpl in *.
  unfold get_agent; unfold nth_order.
    have : of_nat_lt a = of_nat_lt x'.
    apply of_nat_lt_c.
  intros.
  unfold boundness in x'.

  apply andb_true_iff in H'.
  destruct H'.
  apply beq_nat_true in H; apply beq_nat_true in H0.
  subst;rewrite x1.
  clear a x1; move : x' y'.
  
  elim/@rectS : k.
  intros.
  trivial.
  intros. 
  simpl in *.
  rewrite (of_nat_lt_c (lt_S_n n (S n) (le_n (S (S n)))) (lt_S_n n (S n) y')).
  trivial.
}

Defined.








