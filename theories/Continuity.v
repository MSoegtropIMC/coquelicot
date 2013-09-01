(**
This file is part of the Coquelicot formalization of real
analysis in Coq: http://coquelicot.saclay.inria.fr/

Copyright (C) 2011-2013 Sylvie Boldo
#<br />#
Copyright (C) 2011-2013 Catherine Lelay
#<br />#
Copyright (C) 2011-2013 Guillaume Melquiond

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 3 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
COPYING file for more details.
*)

Require Import Reals.
Require Import ssreflect.
Require Import Rcomplements Rbar Locally.
Require Import Compactness Limit.

(** * Limit of fonctions *)

(** ** Definition *)

Definition is_lim' (f : R -> R) (x l : Rbar) :=
  filterlim f (Rbar_locally x) (Rbar_locally' l).

Definition is_lim (f : R -> R) (x l : Rbar) :=
  match l with
    | Finite l =>
      forall eps : posreal, Rbar_locally x (fun y => Rabs (f y - l) < eps)
    | p_infty => forall M : R, Rbar_locally x (fun y => M < f y)
    | m_infty => forall M : R, Rbar_locally x (fun y => f y < M)
  end.
Definition ex_lim (f : R -> R) (x : Rbar) := exists l : Rbar, is_lim f x l.
Definition ex_finite_lim (f : R -> R) (x : Rbar) := exists l : R, is_lim f x l.
Definition Lim (f : R -> R) (x : Rbar) := Lim_seq (fun n => f (Rbar_loc_seq x n)).

Lemma is_lim_ :
  forall f x l,
  is_lim f x l <-> is_lim' f x l.
Proof.
destruct l as [l| |] ; split.
- intros H P [eps LP].
  unfold filtermap.
  generalize (H eps).
  apply filter_imp.
  intros u.
  apply LP.
- intros H eps.
  apply (H (fun y => Rabs (y - l) < eps)).
  now exists eps.
- intros H P [M LP].
  unfold filtermap.
  generalize (H M).
  apply filter_imp.
  intros u.
  apply LP.
- intros H M.
  apply (H (fun y => M < y)).
  now exists M.
- intros H P [M LP].
  unfold filtermap.
  generalize (H M).
  apply filter_imp.
  intros u.
  apply LP.
- intros H M.
  apply (H (fun y => y < M)).
  now exists M.
Qed.

(** Equivalence with standard library Reals *)

Lemma is_lim_Reals_0 (f : R -> R) (x l : R) :
  is_lim f x l -> limit1_in f (fun y => y <> x) l x.
Proof.
  intros H e He ; set (eps := mkposreal e He).
  elim (H eps) ; clear H ; intros (d,Hd) H.
  exists d ; split ; [apply Hd | ].
  intros y Hy ; apply (H y).
  apply Hy.
  apply Hy.
Qed.
Lemma is_lim_Reals_1 (f : R -> R) (x l : R) :
  limit1_in f (fun y => y <> x) l x -> is_lim f x l.
Proof.
  intros H (e,He).
  elim (H e He) ; clear H ; intros d (Hd,H) ; set (delta := mkposreal d Hd).
  exists delta ; intros y Hy Hxy ; apply (H y).
  split.
  by apply Hxy.
  by apply Hy.
Qed.
Lemma is_lim_Reals f x l :
  limit1_in f (fun y => y <> x) l x <-> is_lim f x l.
Proof.
  split ; [apply is_lim_Reals_1|apply is_lim_Reals_0].
Qed.

(** Composition *)

Lemma is_lim_comp' :
  forall {T} {F} {FF : @Filter T F} (f : T -> R) (g : R -> R) (x l : Rbar),
  filterlim f F (Rbar_locally' x) -> is_lim g x l ->
  F (fun y => Finite (f y) <> x) ->
  filterlim (fun y => g (f y)) F (Rbar_locally' l).
Proof.
intros T F FF f g x l Lf Lg Hf.
apply is_lim_ in Lg.
revert Lg.
apply filterlim_compose.
intros P HP.
destruct x as [x| |] ; try now apply Lf.
specialize (Lf _ HP).
unfold filtermap in Lf |- *.
generalize (filter_and _ _ Hf Lf).
apply filter_imp.
intros y [H Hi].
apply Hi.
contradict H.
now apply f_equal.
Qed.

Lemma is_lim_comp_seq (f : R -> R) (u : nat -> R) (x l : Rbar) :
  is_lim f x l ->
  eventually (fun n => Finite (u n) <> x) ->
  is_lim_seq u x -> is_lim_seq (fun n => f (u n)) l.
Proof.
intros Lf Hu Lu.
apply is_lim_seq_.
apply: is_lim_comp' Hu.
now apply is_lim_seq_.
exact Lf.
Qed.

(** Uniqueness *)

Lemma is_lim_unique (f : R -> R) (x l : Rbar) :
  is_lim f x l -> Lim f x = l.
Proof.
  intros.
  unfold Lim.
  rewrite (is_lim_seq_unique _ l) //.
  apply (is_lim_comp_seq f _ x l H).
  exists 1%nat => n Hn.
  case: x {H} => [x | | ] //=.
  apply Rbar_finite_neq, Rgt_not_eq, Rminus_lt_0.
  ring_simplify.
  by apply RinvN_pos.
  by apply is_lim_seq_Rbar_loc_seq.
Qed.
Lemma Lim_correct (f : R -> R) (x : Rbar) :
  ex_lim f x -> is_lim f x (Lim f x).
Proof.
  intros (l,H).
  replace (Lim f x) with l.
    apply H.
  apply sym_eq, is_lim_unique, H.
Qed.

Lemma ex_finite_lim_correct (f : R -> R) (x : Rbar) :
  ex_finite_lim f x <-> ex_lim f x /\ is_finite (Lim f x).
Proof.
  split.
  case => l Hf.
  move: (is_lim_unique f x l Hf) => Hf0.
  split.
  by exists l.
  by rewrite Hf0.
  case ; case => l Hf Hf0.
  exists (real l).
  rewrite -(is_lim_unique _ _ _ Hf).
  rewrite Hf0.
  by rewrite (is_lim_unique _ _ _ Hf).
Qed.
Lemma Lim_correct' (f : R -> R) (x : Rbar) :
  ex_finite_lim f x -> is_lim f x (real (Lim f x)).
Proof.
  intro Hf.
  apply ex_finite_lim_correct in Hf.
  rewrite (proj2 Hf).
  by apply Lim_correct, Hf.
Qed.

Ltac search_lim := let l := fresh "l" in
evar (l : Rbar) ;
match goal with
  | |- Lim _ _ = ?lu => apply is_lim_unique ; replace lu with l ; [ | unfold l]
  | |- is_lim _ _ ?lu => replace lu with l ; [ | unfold l]
end.

(** ** Operations and order *)

(** Extensionality *)

Lemma is_lim_ext_loc (f g : R -> R) (x l : Rbar) :
  Rbar_locally x (fun y => f y = g y)
  -> is_lim f x l -> is_lim g x l.
Proof.
intros Hext Hf.
apply is_lim_ in Hf.
apply is_lim_.
revert Hext Hf.
apply filterlim_ext_loc.
Qed.
Lemma ex_lim_ext_loc (f g : R -> R) (x : Rbar) :
  Rbar_locally x (fun y => f y = g y)
  -> ex_lim f x -> ex_lim g x.
Proof.
  move => H [l Hf].
  exists l.
  by apply is_lim_ext_loc with f.
Qed.
Lemma Lim_ext_loc (f g : R -> R) (x : Rbar) :
  Rbar_locally x (fun y => f y = g y)
  -> Lim g x = Lim f x.
Proof.
  move => H.
  apply sym_eq.
  apply Lim_seq_ext_loc.
  apply: filterlim_Rbar_loc_seq H.
Qed.

Lemma is_lim_ext (f g : R -> R) (x l : Rbar) :
  (forall y, f y = g y)
  -> is_lim f x l -> is_lim g x l.
Proof.
  move => H.
  apply is_lim_ext_loc.
  exact: filter_forall.
Qed.
Lemma ex_lim_ext (f g : R -> R) (x : Rbar) :
  (forall y, f y = g y)
  -> ex_lim f x -> ex_lim g x.
Proof.
  move => H [l Hf].
  exists l.
  by apply is_lim_ext with f.
Qed.
Lemma Lim_ext (f g : R -> R) (x : Rbar) :
  (forall y, f y = g y)
  -> Lim g x = Lim f x.
Proof.
  move => H.
  apply Lim_ext_loc.
  exact: filter_forall.
Qed.

(** Composition *)

Lemma is_lim_comp (f g : R -> R) (x k l : Rbar) :
  is_lim f l k -> is_lim g x l -> Rbar_locally x (fun y => Finite (g y) <> l)
    -> is_lim (fun x => f (g x)) x k.
Proof.
intros Lf Lg Hg.
apply is_lim_.
apply: is_lim_comp' Lf Hg.
now apply is_lim_.
Qed.
Lemma ex_lim_comp (f g : R -> R) (x : Rbar) :
  ex_lim f (Lim g x) -> ex_lim g x -> Rbar_locally x (fun y => Finite (g y) <> Lim g x)
    -> ex_lim (fun x => f (g x)) x.
Proof.
  intros.
  exists (Lim f (Lim g x)).
  apply is_lim_comp with (Lim g x).
  by apply Lim_correct.
  by apply Lim_correct.
  by apply H1.
Qed.
Lemma Lim_comp (f g : R -> R) (x : Rbar) :
  ex_lim f (Lim g x) -> ex_lim g x -> Rbar_locally x (fun y => Finite (g y) <> Lim g x)
    -> Lim (fun x => f (g x)) x = Lim f (Lim g x).
Proof.
  intros.
  apply is_lim_unique.
  apply is_lim_comp with (Lim g x).
  by apply Lim_correct.
  by apply Lim_correct.
  by apply H1.
Qed.

(** Identity *)

Lemma is_lim_id (x : Rbar) :
  is_lim (fun y => y) x x.
Proof.
apply is_lim_.
intros P HP.
apply filterlim_id.
now apply Rbar_locally_le.
Qed.
Lemma ex_lim_id (x : Rbar) :
  ex_lim (fun y => y) x.
Proof.
  exists x.
  by apply is_lim_id.
Qed.
Lemma Lim_id (x : Rbar) :
  Lim (fun y => y) x = x.
Proof.
  apply is_lim_unique.
  by apply is_lim_id.
Qed.

(** Constant *)

Lemma is_lim_const (a : R) (x : Rbar) :
  is_lim (fun _ => a) x a.
Proof.
apply is_lim_.
intros P HP.
now apply filterlim_const.
Qed.
Lemma ex_lim_const (a : R) (x : Rbar) :
  ex_lim (fun _ => a) x.
Proof.
  exists a.
  by apply is_lim_const.
Qed.
Lemma Lim_const (a : R) (x : Rbar) :
  Lim (fun _ => a) x = a.
Proof.
  apply is_lim_unique.
  by apply is_lim_const.
Qed.

(** *** Additive operators *)

(** Opposite *)

Lemma is_lim_opp (f : R -> R) (x l : Rbar) :
  is_lim f x l -> is_lim (fun y => - f y) x (Rbar_opp l).
Proof.
intros Cf.
apply is_lim_ in Cf.
apply is_lim_.
eapply filterlim_compose.
apply Cf.
apply filterlim_opp.
Qed.
Lemma ex_lim_opp (f : R -> R) (x : Rbar) :
  ex_lim f x -> ex_lim (fun y => - f y) x.
Proof.
  case => l Hf.
  exists (Rbar_opp l).
  by apply is_lim_opp.
Qed.
Lemma Lim_opp (f : R -> R) (x : Rbar) :
  Lim (fun y => - f y) x = Rbar_opp (Lim f x).
Proof.
  rewrite -Lim_seq_opp.
  by apply Lim_seq_ext.
Qed.

(** Addition *)

Lemma is_lim_plus (f g : R -> R) (x lf lg : Rbar) :
  is_lim f x lf -> is_lim g x lg ->
  ex_Rbar_plus lf lg ->
  is_lim (fun y => f y + g y) x (Rbar_plus lf lg).
Proof.
intros Cf Cg Hp.
apply is_lim_ in Cf.
apply is_lim_ in Cg.
apply is_lim_.
eapply filterlim_compose_2 ; try eassumption.
now apply filterlim_plus.
Qed.
Lemma ex_lim_plus (f g : R -> R) (x : Rbar) :
  ex_lim f x -> ex_lim g x ->
  ex_Rbar_plus (Lim f x) (Lim g x) ->
  ex_lim (fun y => f y + g y) x.
Proof.
  move/Lim_correct => Hf ; move/Lim_correct => Hg Hl.
  exists (Rbar_plus (Lim f x) (Lim g x)).
  now apply is_lim_plus.
Qed.
Lemma Lim_plus (f g : R -> R) (x : Rbar) :
  ex_lim f x -> ex_lim g x ->
  ex_Rbar_plus (Lim f x) (Lim g x) ->
  Lim (fun y => f y + g y) x = Rbar_plus (Lim f x) (Lim g x).
Proof.
  move/Lim_correct => Hf ; move/Lim_correct => Hg Hl.
  apply is_lim_unique.
  now apply is_lim_plus.
Qed.

(** Subtraction *)

Lemma is_lim_minus (f g : R -> R) (x lf lg : Rbar) :
  is_lim f x lf -> is_lim g x lg ->
  ex_Rbar_minus lf lg ->
  is_lim (fun y => f y - g y) x (Rbar_minus lf lg).
Proof.
  move => Hf Hg Hl.
  apply is_lim_plus ; try assumption.
  now apply is_lim_opp.
Qed.
Lemma ex_lim_minus (f g : R -> R) (x : Rbar) :
  ex_lim f x -> ex_lim g x ->
  ex_Rbar_minus (Lim f x) (Lim g x) ->
  ex_lim (fun y => f y - g y) x.
Proof.
  move => Hf Hg Hl.
  apply ex_lim_plus.
  by apply Hf.
  apply ex_lim_opp.
  by apply Hg.
  rewrite Lim_opp.
  by apply Hl.
Qed.
Lemma Lim_minus (f g : R -> R) (x : Rbar) :
  ex_lim f x -> ex_lim g x ->
  ex_Rbar_minus (Lim f x) (Lim g x) ->
  Lim (fun y => f y - g y) x = Rbar_minus (Lim f x) (Lim g x).
Proof.
  move => Hf Hg Hl.
  rewrite Lim_plus.
  by rewrite Lim_opp.
  by apply Hf.
  apply ex_lim_opp.
  by apply Hg.
  rewrite Lim_opp.
  by apply Hl.
Qed.

(** ** Multiplicative operators *)
(** Multiplicative inverse *)

Lemma is_lim_inv (f : R -> R) (x l : Rbar) :
  is_lim f x l -> l <> 0 -> is_lim (fun y => / f y) x (Rbar_inv l).
Proof.
  intros Hf Hl.
  apply is_lim_ in Hf.
  apply is_lim_.
  apply filterlim_compose with (1 := Hf).
  now apply filterlim_inv.
Qed.
Lemma ex_lim_inv (f : R -> R) (x : Rbar) :
  ex_lim f x -> Lim f x <> 0 -> ex_lim (fun y => / f y) x.
Proof.
  move/Lim_correct => Hf Hlf.
  exists (Rbar_inv (Lim f x)).
  by apply is_lim_inv.
Qed.
Lemma Lim_inv (f : R -> R) (x : Rbar) :
  ex_lim f x -> Lim f x <> 0 -> Lim (fun y => / f y) x = Rbar_inv (Lim f x).
Proof.
  move/Lim_correct => Hf Hlf.
  apply is_lim_unique.
  by apply is_lim_inv.
Qed.

(** Multiplication *)

Lemma is_lim_mult (f g : R -> R) (x lf lg : Rbar) :
  is_lim f x lf -> is_lim g x lg ->
  ex_Rbar_mult lf lg ->
  is_lim (fun y => f y * g y) x (Rbar_mult lf lg).
Proof.
intros Cf Cg Hp.
apply is_lim_ in Cf.
apply is_lim_ in Cg.
apply is_lim_.
eapply filterlim_compose_2 ; try eassumption.
now apply filterlim_mult.
Qed.
Lemma ex_lim_mult (f g : R -> R) (x : Rbar) :
  ex_lim f x -> ex_lim g x ->
  ex_Rbar_mult (Lim f x) (Lim g x) ->
  ex_lim (fun y => f y * g y) x.
Proof.
  move/Lim_correct => Hf ; move/Lim_correct => Hg Hl.
  exists (Rbar_mult (Lim f x) (Lim g x)).
  now apply is_lim_mult.
Qed.
Lemma Lim_mult (f g : R -> R) (x : Rbar) :
  ex_lim f x -> ex_lim g x ->
  ex_Rbar_mult (Lim f x) (Lim g x) ->
  Lim (fun y => f y * g y) x = Rbar_mult (Lim f x) (Lim g x).
Proof.
  move/Lim_correct => Hf ; move/Lim_correct => Hg Hl.
  apply is_lim_unique.
  now apply is_lim_mult.
Qed.

(** Scalar multiplication *)

Lemma is_lim_scal_l (f : R -> R) (a : R) (x l : Rbar) :
  is_lim f x l -> is_lim (fun y => a * f y) x (Rbar_mult a l).
Proof.
  move => Hf.
  case: (Req_dec 0 a) => [<- {a} | Ha].
  replace (Rbar_mult 0 l) with (Finite 0).
  apply is_lim_ext with (fun _ => 0).
  move => y ; by rewrite Rmult_0_l.
  by apply is_lim_const.
  case: l {Hf} => [l | | ] //=.
  by rewrite Rmult_0_l.
  case: Rle_dec (Rle_refl 0) => //= H _.
  case: Rle_lt_or_eq_dec (Rlt_irrefl 0) => //.
  case: Rle_dec (Rle_refl 0) => //= H _.
  case: Rle_lt_or_eq_dec (Rlt_irrefl 0) => //.

  apply is_lim_mult.
  by apply is_lim_const.
  by apply Hf.
  case: l {Hf} => [l | | ] //= ;
  case: Rle_dec => // H.
  case: Rle_lt_or_eq_dec => //.
  case: Rle_lt_or_eq_dec => //.
Qed.
Lemma ex_lim_scal_l (f : R -> R) (a : R) (x : Rbar) :
  ex_lim f x -> ex_lim (fun y => a * f y) x.
Proof.
  case => l Hf.
  exists (Rbar_mult a l).
  by apply is_lim_scal_l.
Qed.
Lemma Lim_scal_l (f : R -> R) (a : R) (x : Rbar) :
  Lim (fun y => a * f y) x = Rbar_mult a (Lim f x).
Proof.
  apply Lim_seq_scal_l.
Qed.

Lemma is_lim_scal_r (f : R -> R) (a : R) (x l : Rbar) :
  is_lim f x l -> is_lim (fun y => f y * a) x (Rbar_mult l a).
Proof.
  move => Hf.
  rewrite Rbar_mult_comm.
  apply is_lim_ext with (fun y => a * f y).
  move => y ; by apply Rmult_comm.
  by apply is_lim_scal_l.
Qed.
Lemma ex_lim_scal_r (f : R -> R) (a : R) (x : Rbar) :
  ex_lim f x -> ex_lim (fun y => f y * a) x.
Proof.
  case => l Hf.
  exists (Rbar_mult l a).
  by apply is_lim_scal_r.
Qed.
Lemma Lim_scal_r (f : R -> R) (a : R) (x : Rbar) :
  Lim (fun y => f y * a) x = Rbar_mult (Lim f x) a.
Proof.
  rewrite Rbar_mult_comm -Lim_seq_scal_l.
  apply Lim_seq_ext.
  move => y ; by apply Rmult_comm.
Qed.

(** Division *)

Lemma is_lim_div (f g : R -> R) (x lf lg : Rbar) :
  is_lim f x lf -> is_lim g x lg -> lg <> 0 ->
  ex_Rbar_div lf lg ->
  is_lim (fun y => f y / g y) x (Rbar_div lf lg).
Proof.
  move => Hf Hg Hlg Hl.
  apply is_lim_mult ; try assumption.
  now apply is_lim_inv.
Qed.
Lemma ex_lim_div (f g : R -> R) (x : Rbar) :
  ex_lim f x -> ex_lim g x -> Lim g x <> 0 ->
  ex_Rbar_div (Lim f x) (Lim g x) ->
  ex_lim (fun y => f y / g y) x.
Proof.
  move => Hf Hg Hlg Hl.
  apply ex_lim_mult ; try assumption.
  now apply ex_lim_inv.
  now rewrite Lim_inv.
Qed.
Lemma Lim_div (f g : R -> R) (x : Rbar) :
  ex_lim f x -> ex_lim g x -> Lim g x <> 0 ->
  ex_Rbar_div (Lim f x) (Lim g x) ->
  Lim (fun y => f y / g y) x = Rbar_div (Lim f x) (Lim g x).
Proof.
  move => Hf Hg Hlg Hl.
  apply is_lim_unique.
  apply is_lim_div ; try apply Lim_correct ; assumption.
Qed.

(** Composition by linear functions *)

Lemma is_lim_comp_lin (f : R -> R) (a b : R) (x l : Rbar) :
  is_lim f (Rbar_plus (Rbar_mult a x) b) l -> a <> 0
  -> is_lim (fun y => f (a * y + b)) x l.
Proof.
  move => Hf Ha.
  apply is_lim_comp with (Rbar_plus (Rbar_mult a x) b).
  by apply Hf.
  search_lim.
  apply is_lim_plus.
  apply is_lim_scal_l.
  apply is_lim_id.
  apply is_lim_const.
  case: (Rbar_mult a x) => //.
  by [].
  case: x {Hf} => [x | | ] //=.
  exists (mkposreal _ Rlt_0_1) => y _ Hy.
  apply Rbar_finite_neq, Rminus_not_eq ; ring_simplify (a * y + b - (a * x + b)).
  rewrite -Rmult_minus_distr_l.
  apply Rmult_integral_contrapositive ; split.
  by [].
  by apply Rminus_eq_contra.
  exists 0 => x Hx.
  apply sym_not_eq in Ha.
  case: Rle_dec => // H.
  case: Rle_lt_or_eq_dec => //.
  exists 0 => x Hx.
  apply sym_not_eq in Ha.
  case: Rle_dec => // H.
  case: Rle_lt_or_eq_dec => //.
Qed.
Lemma ex_lim_comp_lin (f : R -> R) (a b : R) (x : Rbar) :
  ex_lim f (Rbar_plus (Rbar_mult a x) b)
  -> ex_lim (fun y => f (a * y + b)) x.
Proof.
  case => l Hf.
  case: (Req_dec a 0) => [-> {a Hf} | Ha].
  apply ex_lim_ext with (fun _ => f b).
  move => y ; by rewrite Rmult_0_l Rplus_0_l.
  by apply ex_lim_const.
  exists l ; by apply is_lim_comp_lin.
Qed.
Lemma Lim_comp_lin (f : R -> R) (a b : R) (x : Rbar) :
  ex_lim f (Rbar_plus (Rbar_mult a x) b) -> a <> 0 ->
  Lim (fun y => f (a * y + b)) x = Lim f (Rbar_plus (Rbar_mult a x) b).
Proof.
  move => Hf Ha.
  apply is_lim_unique.
  apply is_lim_comp_lin.
  by apply Lim_correct.
  exact: Ha.
Qed.

(** Continuity and limit *)

Lemma is_lim_continuity (f : R -> R) (x : R) :
  continuity_pt f x -> is_lim f x (f x).
Proof.
intros cf.
apply is_lim_.
now apply continuity_pt_filterlim'.
Qed.
Lemma ex_lim_continuity (f : R -> R) (x : R) :
  continuity_pt f x -> ex_finite_lim f x.
Proof.
  move => Hf.
  exists (f x).
  by apply is_lim_continuity.
Qed.
Lemma Lim_continuity (f : R -> R) (x : R) :
  continuity_pt f x -> Lim f x = f x.
Proof.
  move => Hf.
  apply is_lim_unique.
  by apply is_lim_continuity.
Qed.

(** *** Order *)

Lemma is_lim_le_loc (f g : R -> R) (x lf lg : Rbar) :
  is_lim f x lf -> is_lim g x lg
  -> Rbar_locally x (fun y => f y <= g y)
  -> Rbar_le lf lg.
Proof.
  case: lf => [lf | | ] /= Hf ;
  case: lg => [lg | | ] /= Hg Hfg ;
  try by [left | right].

  apply Rbar_finite_le.
  apply Rnot_lt_le => H.
  apply Rminus_lt_0 in H.
  apply (filter_const (F := Rbar_locally x)).
  generalize (filter_and _ _ Hfg (filter_and _ _ (Hf (pos_div_2 (mkposreal _ H))) (Hg (pos_div_2 (mkposreal _ H))))).
  apply filter_imp => {Hfg Hf Hg} /= y [Hfg [Hf Hg]].
  apply: Rlt_not_le Hfg.
  apply Rlt_trans with ((lf + lg) / 2).
  replace ((lf + lg) / 2) with (lg + (lf - lg) / 2) by field.
  apply Rabs_lt_between'.
  apply Hg.
  replace ((lf + lg) / 2) with (lf - (lf - lg) / 2) by field.
  apply Rabs_lt_between'.
  apply Hf.

  left => /=.
  apply (filter_const (F := Rbar_locally x)).
  generalize (filter_and _ _ Hfg (filter_and _ _ (Hf (mkposreal _ (Rle_lt_0_plus_1 _ (Rabs_pos lf)))) (Hg (lf - (Rabs lf + 1))))).
  apply filter_imp => {Hfg Hf Hg} /= y [Hfg [Hf Hg]].
  apply: Rlt_not_le Hfg.
  apply Rlt_trans with (lf - (Rabs lf + 1)).
  apply Hg.
  apply Rabs_lt_between'.
  apply Hf.

  left => /=.
  apply (filter_const (F := Rbar_locally x)).
  generalize (filter_and _ _ Hfg (filter_and _ _ (Hf (lg + (Rabs lg + 1))) (Hg (mkposreal _ (Rle_lt_0_plus_1 _ (Rabs_pos lg)))))).
  apply filter_imp => {Hfg Hf Hg} /= y [Hfg [Hf Hg]].
  apply: Rlt_not_le Hfg.
  apply Rlt_trans with (lg + (Rabs lg + 1)).
  apply Rabs_lt_between'.
  apply Hg.
  apply Hf.

  left => /=.
  apply (filter_const (F := Rbar_locally x)).
  generalize (filter_and _ _ Hfg (filter_and _ _ (Hf 0) (Hg 0))).
  apply filter_imp => {Hfg Hf Hg} y [Hfg [Hf Hg]].
  apply: Rlt_not_le Hfg.
  apply Rlt_trans with 0.
  apply Hg.
  apply Hf.
Qed.

Lemma is_lim_le_p_loc (f g : R -> R) (x : Rbar) :
  is_lim f x p_infty
  -> Rbar_locally x (fun y => f y <= g y)
  -> is_lim g x p_infty.
Proof.
  move => Hf Hfg M.
  generalize (filter_and _ _ Hfg (Hf M)).
  apply filter_imp => {Hfg Hf} y [Hf Hg].
  now apply Rlt_le_trans with (f y).
Qed.

Lemma is_lim_le_m_loc (f g : R -> R) (x : Rbar) :
  is_lim f x m_infty
  -> Rbar_locally x (fun y => g y <= f y)
  -> is_lim g x m_infty.
Proof.
  move => Hf Hfg M.
  generalize (filter_and _ _ Hfg (Hf M)).
  apply filter_imp => {Hfg Hf} y [Hf Hg].
  now apply Rle_lt_trans with (f y).
Qed.


Lemma is_lim_le_le_loc (f g h : R -> R) (x : Rbar) (l : R) :
  is_lim f x l -> is_lim g x l
  -> Rbar_locally x (fun y => f y <= h y <= g y)
  -> is_lim h x l.
Proof.
  move => /= Hf Hg H eps.
  generalize (filter_and _ _ H (filter_and _ _ (Hf eps) (Hg eps))).
  apply filter_imp => {H Hf Hg} y [H [Hf Hg]].
  apply Rabs_lt_between' ; split.
  apply Rlt_le_trans with (2 := proj1 H).
  by apply Rabs_lt_between', Hf.
  apply Rle_lt_trans with (1 := proj2 H).
  by apply Rabs_lt_between', Hg.
Qed.

(** ** Generalized intermediate value theorem *)

Lemma IVT_gen (f : R -> R) (a b y : R) :
  continuity f
  -> Rmin (f a) (f b) <= y <= Rmax (f a) (f b)
  -> { x : R | Rmin a b <= x <= Rmax a b /\ f x = y }.
Proof.
  case: (Req_EM_T a b) => [ <- {b} | Hab].
    rewrite /Rmin /Rmax ; case: Rle_dec (Rle_refl a) (Rle_refl (f a)) ;
    case: Rle_dec => // _ _ _ _ Cf Hy.
    exists a ; split.
    split ; by apply Rle_refl.
    apply Rle_antisym ; by apply Hy.
  wlog: a b Hab / (a < b) => [Hw | {Hab} Hab].
    case: (Rle_lt_dec a b) => Hab'.
    case: (Rle_lt_or_eq_dec _ _ Hab') => {Hab'} // Hab'.
    by apply Hw.
    rewrite (Rmin_comm (f a)) (Rmin_comm a) (Rmax_comm (f a)) (Rmax_comm a) ;
    apply Hw => //.
    by apply Rlt_not_eq.
  rewrite /(Rmin a) /(Rmax a) ; case: Rle_dec (Rlt_le _ _ Hab) => // _ _.
  wlog: f y / (f a <= f b) => [Hw |].
    case: (Rle_lt_dec (f a) (f b)) => Hf' Hf Hy.
    by apply Hw.
    case: (Hw (fun y => - f y) (- y)).
    by apply Ropp_le_contravar, Rlt_le.
    by apply continuity_opp.
    rewrite Rmin_opp_Rmax Rmax_opp_Rmin ;
    split ; apply Ropp_le_contravar, Hy.
    move => x [Hx Hfx].
    exists x ; intuition.
    by rewrite -(Ropp_involutive y) -Hfx Ropp_involutive.
  rewrite /Rmin /Rmax ; case: Rle_dec =>  // _ _.
  wlog: y / (f a < y < f b) => [Hw Hf Hy | Hy Hf _].
    case: Hy => Hay Hyb.
    case: (Rle_lt_or_eq_dec _ _ Hay) => {Hay} [Hay | <- ].
    case: (Rle_lt_or_eq_dec _ _ Hyb) => {Hyb} [Hyb | -> ].
    apply Hw ; intuition.
    exists b ; intuition.
    exists a ; intuition.

  case (IVT (fun x => f x - y) a b).
  apply continuity_minus.
  exact Hf.
  apply continuity_const.
  intros _ _ ; reflexivity.
  exact Hab.
  apply Rlt_minus_l ; rewrite Rplus_0_l ; apply Hy.
  apply Rlt_minus_r ; rewrite Rplus_0_l ; apply Hy.
  intros x [Hx Hfx].
  apply Rminus_diag_uniq in Hfx.
  by exists x.
Qed.

Lemma IVT_Rbar_incr (f : R -> R) (a b la lb : Rbar) (y : R) :
  is_lim f a la -> is_lim f b lb
  -> (forall (x : R), Rbar_lt a x -> Rbar_lt x b -> continuity_pt f x)
  -> Rbar_lt a b
  -> Rbar_lt la y /\ Rbar_lt y lb
  -> {x : R | Rbar_lt a x /\ Rbar_lt x b /\ f x = y}.
Proof.
intros Hfa Hfb Cf Hab Hy.
assert (Hb' : exists b' : R, Rbar_lt b' b /\
        is_upper_bound (fun x => Rbar_lt a x /\ Rbar_lt x b /\ f x <= y) b').
{ assert (Hfb' : Rbar_locally b (fun x => y < f x)).
    apply is_lim_ in Hfb.
    apply Hfb.
    now apply (open_Rbar_gt' _ y).
  clear -Hab Hfb'.
  destruct b as [b| |].
  - destruct Hfb' as [eps He].
    exists (b - eps).
    split.
    apply Rminus_lt_0.
    replace (b - (b - eps)) with (pos eps) by ring.
    apply cond_pos.
    intros u [_ [H1 H2]].
    apply Rnot_lt_le.
    intros Hu.
    apply Rle_not_lt with (1 := H2).
    apply He.
    apply Rabs_lt_between'.
    split.
    exact Hu.
    apply Rlt_le_trans with (1 := H1).
    apply Rlt_le.
    apply Rminus_lt_0.
    replace (b + eps - b) with (pos eps) by ring.
    apply cond_pos.
    now apply Rlt_not_eq.
  - destruct Hfb' as [M HM].
    exists M.
    repeat split.
    intros u [_ [H1 H2]].
    apply Rnot_lt_le.
    intros Hu.
    apply Rle_not_lt with (1 := H2).
    now apply HM.
  - now destruct a. }
assert (Hex : exists x : R, Rbar_lt a x /\ Rbar_lt x b /\ f x <= y).
{ assert (Hfa' : Rbar_locally a (fun x => Rbar_lt x b /\ f x < y)).
    apply filter_and.
    apply Rbar_locally_le.
    now apply open_Rbar_lt'.
    apply is_lim_ in Hfa.
    apply (Hfa (fun u => u < y)).
    now apply (open_Rbar_lt' _ y).
  clear -Hab Hfa'.
  destruct a as [a| |].
  - destruct Hfa' as [eps He].
    exists (a + eps / 2).
    assert (Ha : a < a + eps / 2).
      apply Rminus_lt_0.
      replace (a + eps / 2 - a) with (eps / 2) by ring.
      apply is_pos_div_2.
    split.
    exact Ha.
    assert (H : Rbar_lt (a + eps / 2) b /\ (f (a + eps / 2) < y)).
      apply He.
      replace (a + eps / 2 - a) with (eps / 2) by ring.
      rewrite Rabs_pos_eq.
      apply Rlt_eps2_eps.
      apply cond_pos.
      apply Rlt_le.
      apply is_pos_div_2.
      now apply Rgt_not_eq.
    destruct H as [H1 H2].
    split.
    exact H1.
    now apply Rlt_le.
  - easy.
  - destruct Hfa' as [M HM].
    exists (M - 1).
    assert (H : Rbar_lt (M - 1) b /\ f (M - 1) < y).
      apply HM.
      apply Rminus_lt_0.
      replace (M - (M - 1)) with 1 by ring.
      apply Rlt_0_1.
    destruct H as [H1 H2].
    repeat split.
    exact H1.
    now apply Rlt_le. }
destruct (completeness (fun x => Rbar_lt a x /\ Rbar_lt x b /\ f x <= y)) as [x [Hub Hlub]].
destruct Hb' as [b' Hb'].
now exists b'.
exact Hex.
exists x.
destruct Hb' as [b' [Hb Hb']].
destruct Hex as [x' Hx'].
assert (Hax : Rbar_lt a x).
  apply Rbar_lt_le_trans with x'.
  apply Hx'.
  apply Rbar_finite_le.
  now apply Hub.
assert (Hxb : Rbar_lt x b).
  apply Rbar_le_lt_trans with b'.
  apply Rbar_finite_le.
  now apply Hlub.
  exact Hb.
repeat split ; try assumption.
specialize (Cf _ Hax Hxb).
apply continuity_pt_filterlim in Cf.
destruct (total_order_T (f x) y) as [[H|H]|H].
- assert (H': locally x (fun u => (Rbar_lt a u /\ Rbar_lt u b) /\ f u < y)).
    apply filter_and.
    apply filter_open.
    apply open_and.
    apply open_Rbar_gt.
    apply open_Rbar_lt.
    now split.
    apply (Cf (fun u => u < y)).
    apply filter_open with (2 := H).
    apply open_lt.
  destruct H' as [eps H'].
  elim Rle_not_lt with x (x + eps / 2).
  apply Hub.
  destruct (H' (x + eps / 2)) as [[H1 H2] H3].
  simpl.
  unfold distR.
  replace (x + eps / 2 - x) with (eps / 2) by ring.
  rewrite Rabs_pos_eq.
  apply Rlt_eps2_eps.
  apply cond_pos.
  apply Rlt_le.
  apply is_pos_div_2.
  split.
  exact H1.
  split.
  exact H2.
  now apply Rlt_le.
  apply Rminus_lt_0.
  replace (x + eps / 2 - x) with (eps / 2) by ring.
  apply is_pos_div_2.
- exact H.
- assert (H': locally x (fun u => y < f u)).
    apply (Cf (fun u => y < u)).
    apply filter_open with (2 := H).
    apply open_gt.
  destruct H' as [eps H'].
  elim Rle_not_lt with (x - eps) x.
  apply Hlub.
  intros u Hfu.
  apply Rnot_lt_le.
  intros Hu.
  apply Rle_not_lt with (1 := proj2 (proj2 Hfu)).
  apply H'.
  apply Rabs_lt_between'.
  split.
  exact Hu.
  apply Rle_lt_trans with (1 := Hub u Hfu).
  apply Rminus_lt_0.
  replace (x + eps - x) with (pos eps) by ring.
  apply cond_pos.
  apply Rminus_lt_0.
  replace (x - (x - eps)) with (pos eps) by ring.
  apply cond_pos.
Qed.

Lemma IVT_Rbar_decr (f : R -> R) (a b la lb : Rbar) (y : R) :
  is_lim f a la -> is_lim f b lb
  -> (forall (x : R), Rbar_lt a x -> Rbar_lt x b -> continuity_pt f x)
  -> Rbar_lt a b
  -> Rbar_lt lb y /\ Rbar_lt y la
  -> {x : R | Rbar_lt a x /\ Rbar_lt x b /\ f x = y}.
Proof.
  move => Hla Hlb Cf Hab Hy.
  case: (IVT_Rbar_incr (fun x => - f x) a b (Rbar_opp la) (Rbar_opp lb) (-y)).
  by apply is_lim_opp.
  by apply is_lim_opp.
  move => x Hax Hxb.
  by apply continuity_pt_opp, Cf.
  by apply Hab.
  split ; apply Rbar_opp_lt ;
  rewrite Rbar_opp_involutive /Rbar_opp Ropp_involutive ;
  by apply Hy.
  move => x Hx ; exists x ; intuition.
  by rewrite -(Ropp_involutive y) -H4 Ropp_involutive.
Qed.

(** * 2D-continuity *)

(** ** Definitions *)

Definition continuity_2d_pt f x y :=
  forall eps : posreal, locally_2d (fun u v => Rabs (f u v - f x y) < eps) x y.

Lemma continuity_2d_pt_filterlim :
  forall f x y,
  continuity_2d_pt f x y <->
  filterlim (fun z : R * R => f (fst z) (snd z)) (locally (x,y)) (locally (f x y)).
Proof.
split.
- intros Cf P [eps He].
  specialize (Cf eps).
  apply locally_2d_locally in Cf.
  apply: filter_imp Cf.
  simpl.
  intros [u v].
  apply He.
- intros Cf eps.
  apply locally_2d_locally.
  specialize (Cf (fun z => Rabs (z - f x y) < eps)).
  unfold filtermap in Cf.
  apply: filter_imp (Cf _).
  now intros [u v].
  now exists eps.
Qed.

Lemma continuity_2d_pt_filterlim' :
  forall f x y,
  continuity_2d_pt f x y <->
  filterlim (fun z : Locally.Tn 2 R => f (fst z) (fst (snd z))) (@locally (Locally.Tn 2 R) _ (x,(y,tt))) (locally (f x y)).
Proof.
split.
- intros Cf P [eps He].
  specialize (Cf eps).
  apply locally_2d_locally' in Cf.
  apply: filter_imp Cf.
  simpl.
  intros [u [v t]].
  apply He.
- intros Cf eps.
  apply locally_2d_locally'.
  specialize (Cf (fun z => Rabs (z - f x y) < eps)).
  unfold filtermap in Cf.
  apply: filter_imp (Cf _).
  now intros [u [v t]].
  now exists eps.
Qed.

Lemma uniform_continuity_2d :
  forall f a b c d,
  (forall x y, a <= x <= b -> c <= y <= d -> continuity_2d_pt f x y) ->
  forall eps : posreal, exists delta : posreal,
  forall x y u v,
  a <= x <= b -> c <= y <= d ->
  a <= u <= b -> c <= v <= d ->
  Rabs (u - x) < delta -> Rabs (v - y) < delta ->
  Rabs (f u v - f x y) < eps.
Proof.
intros f a b c d Cf eps.
set (P x y u v := Rabs (f u v - f x y) < pos_div_2 eps).
refine (_ (fun x y Hx Hy => locally_2d_ex_dec (P x y) x y _ (Cf x y Hx Hy _))).
intros delta1.
set (delta2 x y := match Rle_dec a x, Rle_dec x b, Rle_dec c y, Rle_dec y d with
  left Ha, left Hb, left Hc, left Hd => pos_div_2 (projT1 (delta1 x y (conj Ha Hb) (conj Hc Hd))) |
  _, _, _, _ => mkposreal _ Rlt_0_1 end).
destruct (compactness_value_2d a b c d delta2) as (delta,Hdelta).
exists (pos_div_2 delta) => x y u v Hx Hy Hu Hv Hux Hvy.
specialize (Hdelta x y Hx Hy).
apply Rnot_le_lt.
apply: false_not_not Hdelta => Hdelta.
apply Rlt_not_le.
destruct Hdelta as (p&q&(Hap,Hpb)&(Hcq,Hqd)&Hxp&Hyq&Hd).
replace (f u v - f x y) with (f u v - f p q + (f p q - f x y)) by ring.
apply Rle_lt_trans with (1 := Rabs_triang _ _).
rewrite (double_var eps).
revert Hxp Hyq Hd.
unfold delta2.
case Rle_dec => Hap' ; try easy.
case Rle_dec => Hpb' ; try easy.
case Rle_dec => Hcq' ; try easy.
case Rle_dec => Hqd' ; try easy.
clear delta2.
case delta1 => /= r Hr Hxp Hyq Hd.
apply Rplus_lt_compat.
apply Hr.
replace (u - p) with (u - x + (x - p)) by ring.
apply Rle_lt_trans with (1 := Rabs_triang _ _).
rewrite (double_var r).
apply Rplus_lt_compat with (2 := Hxp).
apply Rlt_le_trans with (2 := Hd).
apply Rlt_trans with (1 := Hux).
apply: Rlt_eps2_eps.
apply cond_pos.
replace (v - q) with (v - y + (y - q)) by ring.
apply Rle_lt_trans with (1 := Rabs_triang _ _).
rewrite (double_var r).
apply Rplus_lt_compat with (2 := Hyq).
apply Rlt_le_trans with (2 := Hd).
apply Rlt_trans with (1 := Hvy).
apply: Rlt_eps2_eps.
apply cond_pos.
rewrite Rabs_minus_sym.
apply Hr.
apply Rlt_trans with (1 := Hxp).
apply Rlt_eps2_eps.
apply cond_pos.
apply Rlt_trans with (1 := Hyq).
apply Rlt_eps2_eps.
apply cond_pos.
intros u v.
unfold P.
destruct (Rlt_dec (Rabs (f u v - f x y)) (pos_div_2 eps)) ; [left|right]; assumption.
Qed.

Lemma uniform_continuity_2d_1d :
  forall f a b c,
  (forall x, a <= x <= b -> continuity_2d_pt f x c) ->
  forall eps : posreal, exists delta : posreal,
  forall x y u v,
  a <= x <= b -> c - delta <= y <= c + delta ->
  a <= u <= b -> c - delta <= v <= c + delta ->
  Rabs (u - x) < delta ->
  Rabs (f u v - f x y) < eps.
Proof.
intros f a b c Cf eps.
set (P x y u v := Rabs (f u v - f x y) < pos_div_2 eps).
refine (_ (fun x Hx => locally_2d_ex_dec (P x c) x c _ (Cf x Hx _))).
intros delta1.
set (delta2 x := match Rle_dec a x, Rle_dec x b with
  left Ha, left Hb => pos_div_2 (projT1 (delta1 x (conj Ha Hb))) |
  _, _ => mkposreal _ Rlt_0_1 end).
destruct (compactness_value_1d a b delta2) as (delta,Hdelta).
exists (pos_div_2 delta) => x y u v Hx Hy Hu Hv Hux.
specialize (Hdelta x Hx).
apply Rnot_le_lt.
apply: false_not_not Hdelta => Hdelta.
apply Rlt_not_le.
destruct Hdelta as (p&(Hap,Hpb)&Hxp&Hd).
replace (f u v - f x y) with (f u v - f p c + (f p c - f x y)) by ring.
apply Rle_lt_trans with (1 := Rabs_triang _ _).
rewrite (double_var eps).
revert Hxp Hd.
unfold delta2.
case Rle_dec => Hap' ; try easy.
case Rle_dec => Hpb' ; try easy.
clear delta2.
case delta1 => /= r Hr Hxp Hd.
apply Rplus_lt_compat.
apply Hr.
replace (u - p) with (u - x + (x - p)) by ring.
apply Rle_lt_trans with (1 := Rabs_triang _ _).
rewrite (double_var r).
apply Rplus_lt_compat with (2 := Hxp).
apply Rlt_le_trans with (2 := Hd).
apply Rlt_trans with (1 := Hux).
apply: Rlt_eps2_eps.
apply cond_pos.
apply Rle_lt_trans with (pos_div_2 delta).
now apply Rabs_le_between'.
apply Rlt_le_trans with(1 := Rlt_eps2_eps _ (cond_pos delta)).
apply Rle_trans with (1 := Hd).
apply Rlt_le.
apply Rlt_eps2_eps.
apply cond_pos.
rewrite Rabs_minus_sym.
apply Hr.
apply Rlt_trans with (1 := Hxp).
apply Rlt_eps2_eps.
apply cond_pos.
apply Rle_lt_trans with (pos_div_2 delta).
now apply Rabs_le_between'.
apply Rlt_le_trans with(1 := Rlt_eps2_eps _ (cond_pos delta)).
apply Rle_trans with (1 := Hd).
apply Rlt_le.
apply Rlt_eps2_eps.
apply cond_pos.
intros u v.
unfold P.
destruct (Rlt_dec (Rabs (f u v - f x c)) (pos_div_2 eps)); [left|right] ; assumption.
Qed.

Lemma uniform_continuity_2d_1d' :
  forall f a b c,
  (forall x, a <= x <= b -> continuity_2d_pt f c x) ->
  forall eps : posreal, exists delta : posreal,
  forall x y u v,
  a <= x <= b -> c - delta <= y <= c + delta ->
  a <= u <= b -> c - delta <= v <= c + delta ->
  Rabs (u - x) < delta ->
  Rabs (f v u - f y x) < eps.
Proof.
intros f a b c Cf eps.
assert (T:(forall x : R, a <= x <= b -> continuity_2d_pt (fun x0 y : R => f y x0) x c) ).
intros x Hx e.
destruct (Cf x Hx e) as (d,Hd).
exists d.
intros; now apply Hd.
destruct (uniform_continuity_2d_1d (fun x y => f y x) a b c T eps) as (d,Hd).
exists d; intros.
now apply Hd.
Qed.

Lemma continuity_2d_pt_neq_0 :
  forall f x y,
  continuity_2d_pt f x y -> f x y <> 0 ->
  locally_2d (fun u v => f u v <> 0) x y.
Proof.
intros f x y Cf H.
apply continuity_2d_pt_filterlim in Cf.
apply locally_2d_locally.
apply (Cf (fun y => y <> 0)).
apply filter_open with (2 := H).
apply open_neq.
Qed.

(** ** Operations *)

(** Identity *)

Lemma continuity_pt_id :
  forall x, continuity_pt (fun x => x) x.
Proof.
intros x.
apply continuity_pt_filterlim.
now intros P.
Qed.

Lemma continuity_2d_pt_id1 :
  forall x y, continuity_2d_pt (fun u v => u) x y.
Proof.
  intros x y eps; exists eps; tauto.
Qed.

Lemma continuity_2d_pt_id2 :
  forall x y, continuity_2d_pt (fun u v => v) x y.
Proof.
  intros x y eps; exists eps; tauto.
Qed.

(** Constant functions *)

Lemma continuity_2d_pt_const :
  forall x y c, continuity_2d_pt (fun u v => c) x y.
Proof.
  intros x y c eps; exists eps; rewrite Rminus_eq_0 Rabs_R0.
  intros; apply cond_pos.
Qed.

(** *** Extensionality *)

Lemma continuity_pt_ext_loc :
  forall f g x,
  locally x (fun x => f x = g x) ->
  continuity_pt f x -> continuity_pt g x.
Proof.
intros f g x Heq Cf.
apply continuity_pt_filterlim in Cf.
apply continuity_pt_filterlim.
rewrite -(locally_singleton _ _ Heq).
apply: filterlim_ext_loc Heq Cf.
Qed.

Lemma continuity_pt_ext :
  forall f g x,
  (forall x, f x = g x) ->
  continuity_pt f x -> continuity_pt g x.
Proof.
intros f g x Heq.
apply continuity_pt_ext_loc.
exact: filter_forall.
Qed.

Lemma continuity_2d_pt_ext_loc :
  forall f g x y,
  locally_2d (fun u v => f u v = g u v) x y ->
  continuity_2d_pt f x y -> continuity_2d_pt g x y.
Proof.
intros f g x y Heq Cf.
apply locally_2d_locally in Heq.
apply continuity_2d_pt_filterlim in Cf.
apply continuity_2d_pt_filterlim.
rewrite -(locally_singleton _ _ Heq).
apply: filterlim_ext_loc Cf.
apply: filter_imp Heq.
now intros [u v].
Qed.

Lemma continuity_2d_pt_ext :
  forall f g x y,
  (forall x y, f x y = g x y) ->
  continuity_2d_pt f x y -> continuity_2d_pt g x y.
Proof.
intros f g x y Heq.
apply continuity_2d_pt_ext_loc.
apply locally_2d_locally.
apply: filter_forall.
now intros [u v].
Qed.

(** *** Composition *)

Lemma continuity_1d_2d_pt_comp :
  forall f g x y,
  continuity_pt f (g x y) ->
  continuity_2d_pt g x y ->
  continuity_2d_pt (fun x y => f (g x y)) x y.
Proof.
intros f g x y Cf Cg.
apply continuity_pt_filterlim in Cf.
apply continuity_2d_pt_filterlim in Cg.
apply continuity_2d_pt_filterlim.
apply: filterlim_compose Cg Cf.
Qed.

(** *** Additive operators *)

Lemma continuity_2d_pt_opp (f : R -> R -> R) (x y : R) :
  continuity_2d_pt f x y ->
  continuity_2d_pt (fun u v => - f u v) x y.
Proof.
apply continuity_1d_2d_pt_comp.
apply continuity_pt_opp.
apply continuity_pt_id.
Qed.

Lemma continuity_2d_pt_plus (f g : R -> R -> R) (x y : R) :
  continuity_2d_pt f x y ->
  continuity_2d_pt g x y ->
  continuity_2d_pt (fun u v => f u v + g u v) x y.
Proof.
intros Cf Cg.
apply continuity_2d_pt_filterlim in Cf.
apply continuity_2d_pt_filterlim in Cg.
apply continuity_2d_pt_filterlim.
eapply filterlim_compose_2.
apply Cf.
apply Cg.
now apply (filterlim_plus (f x y) (g x y)).
Qed.

Lemma continuity_2d_pt_minus (f g : R -> R -> R) (x y : R) :
  continuity_2d_pt f x y ->
  continuity_2d_pt g x y ->
  continuity_2d_pt (fun u v => f u v - g u v) x y.
Proof.
  move => Cf Cg.
  apply continuity_2d_pt_plus.
  exact: Cf.
  by apply continuity_2d_pt_opp.
Qed.

(** *** Multiplicative operators *)

Lemma continuity_2d_pt_inv (f : R -> R -> R) (x y : R) :
  continuity_2d_pt f x y ->
  f x y <> 0 ->
  continuity_2d_pt (fun u v => / f u v) x y.
Proof.
intros Cf Df.
apply continuity_2d_pt_filterlim in Cf.
apply continuity_2d_pt_filterlim.
apply filterlim_compose with (1 := Cf).
apply (filterlim_inv (f x y)).
contradict Df.
now injection Df.
Qed.

Lemma continuity_2d_pt_mult (f g : R -> R -> R) (x y : R) :
  continuity_2d_pt f x y ->
  continuity_2d_pt g x y ->
  continuity_2d_pt (fun u v => f u v * g u v) x y.
Proof.
intros Cf Cg.
apply continuity_2d_pt_filterlim in Cf.
apply continuity_2d_pt_filterlim in Cg.
apply continuity_2d_pt_filterlim.
eapply filterlim_compose_2.
apply Cf.
apply Cg.
now apply (filterlim_mult (f x y) (g x y)).
Qed.
