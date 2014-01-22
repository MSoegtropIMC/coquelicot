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

Require Import Reals Rbar.
Require Import ssreflect.
Require Import Limit.
Require Import Hierarchy Continuity Equiv.
Require Import Rcomplements.
Open Scope R_scope.

(** * Linear functions *)

Section LinearFct.

Context {K : AbsRing} {U V : NormedModule K}.

Record is_linear (l : U -> V) := {
  linear_plus : forall (x y : U), l (plus x y) = plus (l x) (l y) ;
  linear_scal : forall (k : K) (x : U), l (scal k x) = scal k (l x) ;
  linear_norm : exists M : R, 0 <= M /\ (forall x : U, norm (l x) <= M * norm x) }.

Lemma linear_zero (l : U -> V) : is_linear l ->
  l zero = zero.
Proof.
  intros Hl.
  rewrite -(scal_zero_l zero).
  rewrite linear_scal.
  exact (scal_zero_l (l zero)).
  exact Hl.
Qed.

Lemma linear_opp (l : U -> V) (x : U) : is_linear l ->
  l (opp x) = opp (l x).
Proof.
  intros Hl.
  apply plus_reg_r with (l x).
  rewrite <- linear_plus, !plus_opp_l.
  by apply linear_zero.
  exact Hl.
Qed.

Lemma linear_cont (l : U -> V) (x : U) :
  is_linear l -> filterlim l (locally x) (locally (l x)).
Proof.
  intros Hl.
  apply filterlim_locally => eps /=.
  apply filter_imp with (1 := (fun y => norm_compat1 (l x) (l y) eps)).
  destruct (norm_compat2 (V := U)) as [M' Hm].
  case: (linear_norm _ Hl) => M Hn.
  assert (0 < eps / (M * M' + 1)).
    apply Rdiv_lt_0_compat.
    by apply eps.
    apply Rplus_le_lt_0_compat.
    apply Rmult_le_pos.
    by apply Hn.
    by apply Rlt_le, M'.
    by apply Rlt_0_1.
  exists (mkposreal _ H) => y Hy.
  specialize (Hm x y _ Hy) ; clear Hy.
  rewrite /minus -linear_opp // -linear_plus //.
  eapply Rle_lt_trans.
  by apply Hn.
  eapply Rle_lt_trans.
  apply Rmult_le_compat_l.
  by apply Hn.
  apply Rlt_le, Hm.
  simpl.
  rewrite -Rmult_assoc.
  apply Rlt_le_trans with ((M * M' + 1) * (eps / (M * M' + 1))).
  apply Rmult_lt_compat_r.
  by [].
  apply Rminus_lt_0 ; ring_simplify ; apply Rlt_0_1.
  apply Req_le ; field.
  apply Rgt_not_eq, Rplus_le_lt_0_compat.
  apply Rmult_le_pos.
  by apply Hn.
  by apply Rlt_le, M'.
  by apply Rlt_0_1.
Qed.


(** zero in a linear function *)
Lemma is_linear_zero : is_linear (fun _ => zero).
Proof.
  repeat split.
  - move => _ _ ; by rewrite plus_zero_l.
  - move => k _ ; by rewrite scal_zero_r.
  - exists 0 ; split.
    by apply Rle_refl.
    move => x ; rewrite Rmult_0_l norm_zero.
    by apply Rle_refl.
Qed.

End LinearFct.

Lemma is_linear_compose {K : AbsRing} {U V W : NormedModule K}
  (l1 : U -> V) (l2 : V -> W) :
  is_linear l1 -> is_linear l2 -> is_linear (fun x => l2 (l1 x)).
Proof.
  intros Hl1 Hl2.
  split.
  - move => x y.
    by rewrite !linear_plus.
  - move => k x.
    by rewrite !linear_scal.
  - destruct (linear_norm _ Hl1) as [M1 Hn1].
    destruct (linear_norm _ Hl2) as [M2 Hn2].
    exists (M2 * M1) ; split.
    now apply Rmult_le_pos.
    move => x.
    eapply Rle_trans.
    by apply Hn2.
    now rewrite Rmult_assoc ; apply Rmult_le_compat_l.
Qed.

Section Op_LinearFct.

Context {K : AbsRing} {V : NormedModule K}.

(** id is a linear function *)
Lemma is_linear_id : is_linear (fun (x : V) => x).
Proof.
  repeat split.
  - exists 1 ; split. 
    by apply Rle_0_1.
    move => x ; rewrite Rmult_1_l.
    by apply Rle_refl.
Qed.

(** opp is a linear function *)
Lemma is_linear_opp : is_linear (@opp V).
Proof.
  repeat split.
  - move => x y.
    now apply opp_plus.
  - move => k x.
    apply sym_eq.
    apply: scal_opp_r.
  - exists 1 ; split. 
    by apply Rle_0_1.
    move => x ; rewrite norm_opp Rmult_1_l.
    by apply Rle_refl.
Qed.

(** plus is a linear function *)
Lemma is_linear_plus : is_linear (fun x : V * V => plus (fst x) (snd x)).
Proof.
  repeat split.
  - move => x y.
    rewrite -!plus_assoc ; apply f_equal.
    rewrite plus_comm -!plus_assoc.
    by apply f_equal, @plus_comm.
  - move => k x.
    now rewrite scal_distr_l.
  - exists 2 ; split.
    now apply Rlt_le, Rlt_0_2.
    move => x /= ; eapply Rle_trans.
    by apply @norm_triangle.
    rewrite Rmult_plus_distr_r Rmult_1_l ; apply Rplus_le_compat.
    apply Rle_trans with (2 := proj1 (sqrt_plus_sqr _ _)).
    rewrite -> Rabs_pos_eq by apply norm_ge_0.
    by apply Rmax_l.
    apply Rle_trans with (2 := proj1 (sqrt_plus_sqr _ _)).
    rewrite -> (Rabs_pos_eq (norm (snd x))) by apply norm_ge_0.
    by apply Rmax_r.
Qed.

(** [fun k => scal k x] is a linear function *)
Lemma is_linear_scal_l (x : V) :
  is_linear (fun k : K => scal k x).
Proof.
  split.
  - move => u v ; by apply @scal_distr_r.
  - move => u v /= ; apply sym_eq, @scal_assoc.
  - exists (norm x) ; split.
    by apply norm_ge_0.
    move => k /=.
    now rewrite Rmult_comm ; apply @norm_scal.
Qed.

(** [fun x => scal k x] is a linear function if [mult] is commutative *)
Lemma is_linear_scal_r (k : K) :
  (forall n m : K, mult n m = mult m n)
  -> is_linear (fun x : V => scal k x).
Proof.
  split.
  - move => u v ; by apply @scal_distr_l.
  - move => u v /= ; apply sym_eq ; rewrite !@scal_assoc.
    by rewrite H.
  - exists (abs k) ; split.
    by apply @abs_ge_0.
    move => x /=.
    now apply @norm_scal.
Qed.

End Op_LinearFct.

Lemma is_linear_prod {K : AbsRing} {T U V : NormedModule K}
  (l1 : T -> U) (l2 : T -> V) :
  is_linear l1 -> is_linear l2 -> is_linear (fun t : T => (l1 t, l2 t)).
Proof.
  intros H1 H2.
  split.
  - intros x y.
    apply injective_projections ; simpl.
    by apply H1.
    by apply H2.
  - intros k x.
    apply injective_projections ; simpl.
    by apply H1.
    by apply H2.
  - destruct (linear_norm l1 H1) as [M1 [HM1 Hn1]].
    destruct (linear_norm l2 H2) as [M2 [HM2 Hn2]].
    exists (sqrt 2 * Rmax M1 M2)%R ; split.
    apply Rmult_le_pos.
    apply sqrt_pos.
    by apply Rmax_case.
    intros x.
    eapply Rle_trans.
    apply norm_prod.
    rewrite Rmult_assoc.
    apply Rmult_le_compat_l.
    by apply sqrt_pos.
    rewrite Rmult_max_distr_r.
    apply Rmax_case.
    by eapply Rle_trans, Rmax_l.
    by eapply Rle_trans, Rmax_r.
    by apply norm_ge_0.
Qed.

Lemma is_linear_fst {K : AbsRing} {U V : NormedModule K} :
  is_linear (fun t : U * V => fst t).
Proof.
  split.
  - intros [x1 x2] [y1 y2] ; by simpl.
  - intros k [x1 x2] ; by simpl.
  - exists 1 ; split.
    by apply Rle_0_1.
    intros [x1 x2] ; simpl fst ; rewrite Rmult_1_l.
    eapply Rle_trans.
    2: by apply norm_prod.
    by apply Rmax_l.
Qed.

Lemma is_linear_snd {K : AbsRing} {U V : NormedModule K} :
  is_linear (fun t : U * V => snd t).
Proof.
  split.
  - intros [x1 x2] [y1 y2] ; by simpl.
  - intros k [x1 x2] ; by simpl.
  - exists 1 ; split.
    by apply Rle_0_1.
    intros [x1 x2] ; simpl snd ; rewrite Rmult_1_l.
    eapply Rle_trans.
    2: by apply norm_prod.
    by apply Rmax_r.
Qed.

Section Linear_domin.

Context {T : Type} {Kw K : AbsRing} {W : NormedModule Kw} {U V : NormedModule K}.

Lemma is_domin_linear {F : (T -> Prop) -> Prop} {FF : Filter F} (f : T -> W) (g : T -> U) (l : U -> V) :
  is_linear l -> is_domin F f g -> is_domin F f (fun t => l (g t)).
Proof.
  intros [_ _ [M [Hm Hn]]] H eps.
  assert (He : 0 < eps / (1 + M)).
    apply Rdiv_lt_0_compat.
    by apply eps.
    apply Rplus_lt_le_0_compat.
    by apply Rlt_0_1.
    by apply Hm.
  specialize (H (mkposreal _ He)).
  move: H ;
  apply filter_imp => /= x Hx.
  apply Rle_trans with (1 := Hn _).
  apply Rle_trans with ((1 + M) * norm (g x)).
  apply Rmult_le_compat_r.
  by apply norm_ge_0.
  rewrite -{1}(Rplus_0_l M).
  apply Rplus_le_compat_r.
  apply Rle_0_1.
  rewrite Rmult_comm ; apply Rle_div_r.
  apply Rplus_lt_le_0_compat.
  by apply Rlt_0_1.
  by apply Hm.
  by rewrite /Rdiv Rmult_assoc (Rmult_comm (norm _)) -Rmult_assoc.
Qed.

End Linear_domin.

(** * Differentiability using filters *)

Section Diff.

Context {K : AbsRing} {U : NormedModule K} {V : NormedModule K}.

Definition filterdiff (f : U -> V) F (l : U -> V) :=
  is_linear l /\ forall x, is_filter_lim F x ->
  is_domin F (fun y : U => minus y x) (fun y => minus (minus (f y) (f x)) (l (minus y x))).

Definition ex_filterdiff (f : U -> V) F :=
  exists (l : U -> V), filterdiff f F l.

Lemma filterdiff_cont {F} {FF : Filter F} (f : U -> V) :
  ex_filterdiff f F -> forall x, is_filter_lim F x -> filterlim f F (locally (f x)).
Proof.
  intros [l [Hl Df]] x Hx.
  specialize (Df x Hx).
  apply filterlim_locally => //= eps.
  apply filter_imp with (1 := fun y => norm_compat1 (f x) (f y) eps).
  specialize (Df (mkposreal _ Rlt_0_1)) ; simpl in Df.
  destruct (linear_norm _ Hl) as [M Hm].
  assert (F (fun y => norm (minus (f y) (f x)) <= (M + 1) * norm (minus y x))).
    move: Df ; apply filter_imp => y Hy.
    rewrite Rmult_1_l in Hy.
    apply Rle_trans with (1 := norm_triangle_inv _ _) in Hy.
    apply Rabs_le_between' in Hy.
    eapply Rle_trans.
    by apply Hy.
    apply Rle_minus_r ; ring_simplify.
    by apply Hm.
  move: H => {Df} Df.
  destruct (norm_compat2 (V := U)) as [M' Hm'].
  assert (0 < eps / ((M+1) * M')).
    apply Rdiv_lt_0_compat.
    by apply eps.
    apply Rmult_lt_0_compat.
    apply Rplus_le_lt_0_compat.
    by apply Hm.
    by apply Rlt_0_1.
    by apply M'.
  specialize (Hx _ (locally_ball x (mkposreal _ H))).
  apply filter_imp with (1 := fun y => Hm' x y _) in Hx => {Hm'}.
  generalize (filter_and _ _ Hx Df) => /=.
  apply filter_imp => y [Hy Hy'].
  apply Rle_lt_trans with (1 := Hy').
  eapply Rlt_le_trans.
  apply Rmult_lt_compat_l.
  apply Rplus_le_lt_0_compat.
  by apply Hm.
  by apply Rlt_0_1.
  by apply Hy.
  apply Req_le ; field ; split ; apply Rgt_not_eq.
  by apply M'.
  apply Rplus_le_lt_0_compat.
  by apply Hm.
  by apply Rlt_0_1.
Qed.

Lemma filterdiff_locally {F} {FF : ProperFilter F} (f : U -> V) x l :
  is_filter_lim F x ->
  filterdiff f (locally x) l ->
  filterdiff f F l.
Proof.
intros Fx [Hl Df].
split.
exact Hl.
intros z Fz.
specialize (Df _ (fun P H => H)).
generalize (is_filter_lim_unique _ _ Fx Fz) => Hxz.
assert (norm (minus x z) = 0)%R.
  apply Req_lt_aux => e.
  rewrite Rminus_0_r Rabs_pos_eq.
  destruct (norm_compat2 (V := U)) as [M HM].
  move: (fun eps => HM _ _ _ (ball_sym _ _ _ (Hxz eps))) => {HM Hxz} HM.
  replace (pos e) with (M * (e/M))%R.
  generalize (fun H => HM (mkposreal (e/M) H)) => {HM} /= HM.
  apply HM.
  apply Rdiv_lt_0_compat.
  by apply e.
  by apply M.
  field ; apply Rgt_not_eq, M.
  by apply norm_ge_0.
eapply is_domin_le.
2: apply Fx.
apply domin_rw_l with (fun y : U => minus y x).
move => eps /=.
apply filter_forall => y.
replace (minus (minus y z) (minus y x)) with (minus x z).
rewrite H.
apply Rmult_le_pos.
by apply Rlt_le, eps.
by apply norm_ge_0.
rewrite /minus opp_plus opp_opp.
rewrite (plus_comm y) -plus_assoc plus_comm.
apply f_equal.
by rewrite plus_assoc plus_opp_r plus_zero_l.
eapply domin_rw_r.
2: by apply Df.
move => eps /=.
apply filter_forall => y.
eapply Rle_trans.
2: apply Rmult_le_pos.
apply Req_le.
apply Req_le_aux => e.
rewrite Rminus_0_r Rabs_pos_eq.
destruct (Df e) as [d Hd].
move: (Hd _ (Hxz _)) => {Hd} Hd.
eapply Rle_trans.
eapply Rle_trans.
2: apply Hd.
apply Req_le.
rewrite -norm_opp opp_minus.
apply f_equal.
rewrite /minus !(linear_plus l Hl) !(linear_opp l _ Hl) !opp_plus !opp_opp -!plus_assoc.
rewrite (plus_comm (f y)) !(plus_comm (f z)) -!plus_assoc.
apply f_equal.
rewrite (plus_comm (opp (l y))) !(plus_comm (opp (l z))) -!plus_assoc.
apply f_equal.
rewrite (plus_comm (opp (f y))) (plus_comm (l y)) -!plus_assoc (plus_assoc (opp (l y))) plus_opp_l plus_zero_l.
apply f_equal.
by rewrite plus_comm -plus_assoc plus_opp_l plus_zero_r.
rewrite -norm_opp opp_minus H Rmult_0_r.
by apply Rlt_le, e.
by apply norm_ge_0.
by apply Rlt_le, eps.
by apply norm_ge_0.
Qed.
Lemma ex_filterdiff_locally {F} {FF : ProperFilter F} (f : U -> V) x :
  is_filter_lim F x ->
  ex_filterdiff f (locally x) ->
  ex_filterdiff f F.
Proof.
  intros Fx [l Df].
  eexists.
  apply filterdiff_locally with x.
  by [].
  by apply Df.
Qed.

(** ** Operations *)

Lemma filterdiff_ext_lin {F} {FF : Filter F} (f : U -> V) (l1 l2 : U -> V) :
  filterdiff f F l1 -> (forall y, l1 y = l2 y) -> filterdiff f F l2.
Proof.
  intros [Hl1 Hf1] Hl ; split => [ | x Hx eps].
  + split.
    - intros x y ; rewrite -!Hl.
      by apply linear_plus.
    - intros k x ; rewrite -!Hl.
      by apply linear_scal.
    - destruct (linear_norm _ Hl1) as [M Hm].
      exists M ; split.
      by apply Hm.
      move => x ; now rewrite -Hl.
  + move: (Hf1 x Hx eps).
    apply filter_imp => y.
    by rewrite !Hl.
Qed.

Lemma filterdiff_ext_loc {F} {FF : Filter F} (f g : U -> V) (l : U -> V) :
  F (fun y => f y = g y) -> (forall x, is_filter_lim F x -> f x = g x)
  -> filterdiff f F l -> filterdiff g F l.
Proof.
  move => H H0 [Hl Df].
  split => //.
  move => x Hx eps.
  specialize (H0 x Hx).
  specialize (Df x Hx eps).
  apply filter_and with (1 := H) in Df.
  move: Df ; apply filter_imp => y [Hy].
  apply Rle_trans.
  by apply Req_le ; rewrite Hy H0.
Qed.
Lemma ex_filterdiff_ext_loc {F} {FF : Filter F} (f g : U -> V) :
  F (fun y => f y = g y) -> (forall x, is_filter_lim F x -> f x = g x)
  -> ex_filterdiff f F -> ex_filterdiff g F.
Proof.
  intros H H0 [l Hl].
  exists l ; by apply filterdiff_ext_loc with f.
Qed.

Lemma filterdiff_ext_locally (f g : U -> V) (x : U) (l : U -> V) :
  locally x (fun y => f y = g y)
  -> filterdiff f (locally x) l -> filterdiff g (locally x) l.
Proof.
  move => H.
  apply filterdiff_ext_loc with (1 := H).
  move => y Hy.
  destruct H as [d Hd].
  apply Hd.
  by apply is_filter_lim_locally_unique.
Qed.
Lemma ex_filterdiff_ext_locally (f g : U -> V) x :
  locally x (fun y => f y = g y)
  -> ex_filterdiff f (locally x) -> ex_filterdiff g (locally x).
Proof.
  intros H [l Hl].
  exists l ; by apply filterdiff_ext_locally with f.
Qed.

Lemma filterdiff_ext {F} {FF : Filter F} (f g : U -> V) (l : U -> V) :
  (forall y , f y = g y)
  -> filterdiff f F l -> filterdiff g F l.
Proof.
  move => H.
  apply filterdiff_ext_loc => //.
  now apply filter_imp with (2 := filter_true).
Qed.
Lemma ex_filterdiff_ext {F} {FF : Filter F} (f g : U -> V) :
  (forall y , f y = g y)
  -> ex_filterdiff f F -> ex_filterdiff g F.
Proof.
  intros H [l Hl].
  exists l ; by apply filterdiff_ext with f.
Qed.

Lemma filterdiff_const {F} {FF : Filter F} (a : V) :
  filterdiff (fun _ => a) F (fun _ => zero).
Proof.
  split.
  by apply is_linear_zero.
  move => x Hx eps.
  apply filter_imp with (2 := filter_true) => y _.
  rewrite /minus plus_opp_r plus_zero_l norm_opp norm_zero.
  apply Rmult_le_pos.
  by apply Rlt_le, eps.
  by apply norm_ge_0.
Qed.
Lemma ex_filterdiff_const {F} {FF : Filter F} (a : V) :
  ex_filterdiff (fun _ => a) F.
Proof.
  intros.
  exists (fun _ => zero).
  by apply filterdiff_const.
Qed.

Lemma filterdiff_linear {F} {FF : Filter F}
  (l : U -> V) :
  is_linear l -> filterdiff l F l.
Proof.
  move => Hl ; split.
  by [].
  move => x Hx eps.
  apply filter_forall => y.
  rewrite /minus -(linear_opp l x Hl) -linear_plus // plus_opp_r norm_zero.
  apply Rmult_le_pos.
  apply Rlt_le, eps.
  by apply norm_ge_0.
Qed.
Lemma ex_filterdiff_linear {F} {FF : Filter F}
  (l : U -> V) :
  is_linear l -> ex_filterdiff l F.
Proof.
  intro Hl ; exists l; by apply filterdiff_linear.
Qed.

End Diff.

Section Diff_compose.

Context {K : AbsRing} {U V W : NormedModule K}.

Lemma filterdiff_compose
  {F} {FF : Filter F} f g (lf : U -> V) (lg : V -> W) :
  filterdiff f F lf -> filterdiff g (filtermap f F) lg
  -> filterdiff (fun y => g (f y)) F (fun y => lg (lf y)).
Proof.
  intros Df Dg.
  split.
    apply is_linear_compose.
    by apply Df.
    by apply Dg.
  intros x Hx.
  assert (Cf : filterlim f F (locally (f x))).
    apply filterdiff_cont with (2 := Hx).
    eexists ; by apply Df.
  assert (is_domin (filtermap f F) (fun y : V => minus y (f x))
    (fun y : V => minus (minus (g y) (g (f x))) (lg (minus y (f x))))).
    apply Dg.
    move => P HP.
    by apply Cf.
  destruct Dg as [Hg _].
  rename H into Dg.
  destruct Df as [Hf Df].
  apply domin_rw_r with
    (fun y : U => plus (minus (minus (g (f y)) (g (f x))) (lg (minus (f y) (f x))))
                       (lg (minus (minus (f y) (f x)) (lf (minus y x))))).
  apply equiv_ext_loc.
  apply filter_forall => y.
  rewrite /minus -!plus_assoc.
  repeat apply f_equal.
  rewrite plus_assoc.
  rewrite (linear_plus _ Hg (plus _ _)).
  rewrite plus_assoc.
  rewrite plus_opp_l plus_zero_l.
  by apply linear_opp.
  
  apply domin_plus.
  intros eps.
  destruct (linear_norm _ Hf) as [mf [Hmf Hnf]].
  assert (F (fun y => norm (minus (f y) (f x)) <= (1 + mf) * norm  (minus y x))).
    specialize (Df x Hx (mkposreal _ Rlt_0_1)).
    move: Df ; apply filter_imp.
    move => y /= Hy.
    replace (minus (f y) (f x))
    with (plus (minus (minus (f y) (f x)) (lf (minus y x))) (lf (minus y x))).
    eapply Rle_trans.
    apply @norm_triangle.
    rewrite Rmult_plus_distr_r.
    apply Rplus_le_compat.
    exact Hy.
    by apply Hnf.
    by rewrite {1}/minus -plus_assoc plus_opp_l plus_zero_r.
  clear Df ; rename H into Df.
  assert (He : 0 < eps / (1 + mf)).
    apply Rdiv_lt_0_compat.
    by apply eps.
    apply Rplus_lt_le_0_compat.
    by apply Rlt_0_1.
    exact Hmf.
  specialize (Dg (mkposreal _ He)).
  unfold filtermap in Dg.
  generalize (filter_and _ _ Df Dg).
  apply filter_imp => /= y {Df Dg} [Df Dg].
  apply Rle_trans with (1 := Dg).
  unfold Rdiv.
  rewrite Rmult_assoc.
  apply Rmult_le_compat_l.
  apply Rlt_le, eps.
  rewrite Rmult_comm ; apply Rle_div_l.
  apply Rplus_lt_le_0_compat.
  by apply Rlt_0_1.
  exact Hmf.
  rewrite Rmult_comm ; by apply Df.
  
  specialize (Df x Hx).
  by apply is_domin_linear.
Qed.

Lemma ex_filterdiff_compose
  {F} {FF : Filter F} (f : U -> V) (g : V -> W) :
  ex_filterdiff f F -> ex_filterdiff g (filtermap f F)
  -> ex_filterdiff (fun y => g (f y)) F.
Proof.
  intros [lf Df] [lg Dg].
  eexists ; eapply filterdiff_compose ; eassumption.
Qed.

Lemma filterdiff_compose'
  f g x (lf : U -> V) (lg : V -> W) :
  filterdiff f (locally x) lf -> filterdiff g (locally (f x)) lg
  -> filterdiff (fun y => g (f y)) (locally x) (fun y => lg (lf y)).
Proof.
  intros.
  apply filterdiff_compose.
  by [].
  apply filterdiff_locally with (f x).
  apply is_filter_lim_filtermap => //.
  apply filterdiff_cont => //.
  eexists ; by apply H.
  by [].
Qed.

Lemma ex_filterdiff_compose'
  (f : U -> V) (g : V -> W) x :
  ex_filterdiff f (locally x) -> ex_filterdiff g (locally (f x))
  -> ex_filterdiff (fun y => g (f y)) (locally x).
Proof.
  intros [lf Df] [lg Dg].
  eexists.
  apply filterdiff_compose' ; eassumption.
Qed.

End Diff_compose.

Section Diff_compose2.

Context {K : AbsRing} {T U V : NormedModule K}.

Section Diff_compose2'.

Context {W : NormedModule K}.

Lemma filterdiff_compose_2
  {F : (T -> Prop) -> Prop} {FF : Filter F} :
  forall (f : T -> U) (g : T -> V) (h : U -> V -> W) (lf : T -> U) (lg : T -> V)
    (lh : U -> V -> W),
    filterdiff f F lf ->
    filterdiff g F lg ->
    filterdiff (fun t => h (fst t) (snd t)) (filtermap (fun t => (f t,g t)) F) (fun t => lh (fst t) (snd t)) ->
    filterdiff (fun y : T => h (f y) (g y)) F (fun y : T => lh (lf y) (lg y)).
Proof.
  intros f g h lf lg lh [Hf Df] [Hg Dg] Dh.
  apply (filterdiff_compose (fun t => (f t, g t)) _ (fun t => (lf t, lg t)) _) in Dh.
  by [].
  split.
  by apply is_linear_prod.
  intros x Hx eps.
  assert (0 < eps / sqrt 2).
    apply Rdiv_lt_0_compat.
    by apply eps.
    apply Rlt_sqrt2_0.
  generalize (filter_and _ _ (Df x Hx (mkposreal _ H)) (Dg x Hx (mkposreal _ H))).
  simpl pos.
  apply filter_imp ; intros y [Hnf Hng].
  eapply Rle_trans.
  apply norm_prod.
  simpl fst ; simpl snd.
  eapply Rle_trans.
  apply Rmult_le_compat_l.
  by apply sqrt_pos.
  apply Rmax_case.
  apply Hnf.
  apply Hng.
  apply Req_le ; field.
  apply Rgt_not_eq, Rlt_sqrt2_0.
Qed.

Lemma ex_filterdiff_compose_2
  {F : (T -> Prop) -> Prop} {FF : Filter F} :
  forall (f : T -> U) (g : T -> V) (h : U -> V -> W),
    ex_filterdiff f F ->
    ex_filterdiff g F ->
    ex_filterdiff (fun t => h (fst t) (snd t)) (filtermap (fun t => (f t,g t)) F) ->
    ex_filterdiff (fun y : T => h (f y) (g y)) F.
Proof.
  intros f g h [lf Df] [lg Dg] [lh Dh].
  set lh' := fun x y => lh (x,y).
  eexists ; eapply (filterdiff_compose_2 _ _ _ _ _ lh') ; try eassumption.
  eapply filterdiff_ext_lin.
  by apply Dh.
  by case.
Qed.

End Diff_compose2'.

Context {W : NormedModule K}.

Lemma filterdiff_compose'_2 :
  forall (f : T -> U) (g : T -> V) (h : U -> V -> W) x (lf : T -> U) (lg : T -> V)
    (lh : U -> V -> W),
    filterdiff f (locally x) lf ->
    filterdiff g (locally x) lg ->
    filterdiff (fun t => h (fst t) (snd t)) (locally (f x,g x)) (fun t => lh (fst t) (snd t)) ->
    filterdiff (fun y : T => h (f y) (g y)) (locally x) (fun y : T => lh (lf y) (lg y)).
Proof.
  intros.
  apply filterdiff_compose_2.
  by [].
  by [].
  apply filterdiff_locally with (f x, g x).
  apply (is_filter_lim_filtermap _ _ (fun t : T => (f t, g t))) => //.
  apply (filterdiff_cont (fun t : T => (f t, g t))) => //.
  apply ex_filterdiff_compose_2.
  by exists lf.
  by exists lg.
  apply ex_filterdiff_linear.
  apply is_linear_prod.
  apply is_linear_fst.
  by apply is_linear_snd.
  by [].
Qed.

Lemma ex_filterdiff_compose'_2 :
  forall (f : T -> U) (g : T -> V) (h : U -> V -> W) x,
    ex_filterdiff f (locally x) ->
    ex_filterdiff g (locally x) ->
    ex_filterdiff (fun t => h (fst t) (snd t)) (locally (f x,g x)) ->
    ex_filterdiff (fun y : T => h (f y) (g y)) (locally x).
Proof.
  intros f g h x [lf Df] [lg Dg] [lh Dh].
  exists (fun x => lh (lf x,lg x)).
  apply (filterdiff_compose'_2 f g h x lf lg (fun x y => lh (x,y))) ; try eassumption.
  eapply filterdiff_ext_lin ; try eassumption.
  by case.
Qed.

End Diff_compose2.

Section Operations.

Context {K : AbsRing} {V : NormedModule K}.

Lemma filterdiff_id (F : (V -> Prop) -> Prop) :
  filterdiff (fun y => y) F (fun y => y).
Proof.
  split.
  by apply is_linear_id.
  
  move => x Hx eps.
  apply Hx ; exists eps => y /= Hy.
  rewrite /minus plus_opp_r norm_zero.
  apply Rmult_le_pos.
  by apply Rlt_le, eps.
  by apply norm_ge_0.
Qed.

Lemma ex_filterdiff_id (F : (V -> Prop) -> Prop) :
  ex_filterdiff (fun y => y) F.
Proof.
  eexists.
  by apply filterdiff_id.
Qed.

Lemma filterdiff_opp (F : (V -> Prop) -> Prop) :
  filterdiff opp F opp.
Proof.
  split.
  by apply is_linear_opp.
  move => x Hx eps.
  apply Hx.
  exists eps => y /= Hy.
  rewrite /minus -!opp_plus plus_opp_r norm_opp norm_zero.
  apply Rmult_le_pos.
  by apply Rlt_le, eps.
  by apply norm_ge_0.
Qed.

Lemma ex_filterdiff_opp (F : (V -> Prop) -> Prop) :
  ex_filterdiff opp F.
Proof.
  eexists.
  by apply filterdiff_opp.
Qed.

Lemma filterdiff_plus (F : (V * V -> Prop) -> Prop) :
  filterdiff (fun u => plus (fst u) (snd u)) F (fun u => plus (fst u) (snd u)).
Proof.
  split.
  by apply is_linear_plus.
  move => x Hx eps.
  apply Hx ; exists eps => u /= Hu.
  set v := plus (plus _ _) _.
  replace v with (minus (plus (fst u) (snd u)) (plus (fst x) (snd x))).
  rewrite /minus plus_opp_r norm_zero.
  apply Rmult_le_pos.
  by apply Rlt_le, eps.
  by apply sqrt_pos.
  rewrite /v /minus -!plus_assoc ; apply f_equal.
  rewrite opp_plus plus_comm -!plus_assoc ; apply f_equal, @plus_comm.
Qed.

Lemma ex_filterdiff_plus (F : (V * V -> Prop) -> Prop) :
  ex_filterdiff (fun u => plus (fst u) (snd u)) F.
Proof.
  eexists.
  by apply filterdiff_plus.
Qed.

Lemma filterdiff_minus (F : (V * V -> Prop) -> Prop) :
  filterdiff (fun u => minus (fst u) (snd u)) F (fun u => minus (fst u) (snd u)).
Proof.
  split.
  apply (is_linear_compose (fun u => (fst u, opp (snd u))) (fun u => plus (fst u) (snd u))).
  apply is_linear_prod.
  by apply is_linear_fst.
  apply is_linear_compose.
  by apply is_linear_snd.
  by apply is_linear_opp.
  by apply is_linear_plus.
  move => x Hx eps.
  apply Hx ; exists eps => u Hu.
  simpl fst ; simpl snd.
  set v := minus (plus _ (opp (fst x))) _.
  replace v with (minus (minus (fst u) (snd u)) (minus (fst x) (snd x))).
  rewrite /minus plus_opp_r norm_zero.
  apply Rmult_le_pos.
  by apply Rlt_le, eps.
  by apply sqrt_pos.
  rewrite /v /minus -!plus_assoc ; apply f_equal.
  rewrite !opp_plus !opp_opp plus_comm -!plus_assoc ;
  apply f_equal, @plus_comm.
Qed.

Lemma ex_filterdiff_minus (F : (V * V -> Prop) -> Prop) :
  ex_filterdiff (fun u => minus (fst u) (snd u)) F.
Proof.
  eexists.
  by apply filterdiff_minus.
Qed.

Lemma filterdiff_scal : forall {F} {FF : ProperFilter F} (x : K * V), 
  is_filter_lim F x ->
  (forall (n m : K), mult n m = mult m n) ->
  filterdiff (fun t : K * V => scal (fst t) (snd t)) F
    (fun t => plus (scal (fst t) (snd x)) (scal (fst x) (snd t))).
Proof.
  move => F FF [x1 x2] Hx Hcomm ; split.
  - apply (is_linear_compose (fun t : K * V => (scal (fst t) x2,scal x1 (snd t))) (fun t : V * V => plus (fst t) (snd t))).
    apply is_linear_prod.
    apply (is_linear_compose (fun t : K * V => fst t) (fun k : K => scal k x2)).
    by apply is_linear_fst.
    by apply is_linear_scal_l.
    apply is_linear_compose.
    by apply is_linear_snd.
    by apply is_linear_scal_r.
    apply is_linear_plus.
  - move => y Hy.
    generalize (is_filter_lim_unique _ _ Hx Hy) => {Hy} Hy eps.
    apply Hx ; clear Hx.
    destruct (norm_compat2 (V := V)) as [M HM].
    assert (0 < Rmin (eps / 2) (eps / 2 / M)).
      apply Rmin_case.
      by apply is_pos_div_2.
      apply Rdiv_lt_0_compat.
      by apply is_pos_div_2.
      by apply M.
    set eps' := mkposreal _ H.

    exists eps' => z Hz.
    move: (conj (proj1 Hz) (HM _ _ _ (proj2 Hz))) => {Hz} Hz.
    specialize (Hy eps').
    move: (conj (proj1 Hy) (HM _ _ _ (proj2 Hy))) => {Hy} Hy.
    destruct y as [y1 y2].
    destruct z as [z1 z2].
    simpl in Hy, Hz ; simpl fst in Hy, Hz |- * ; simpl snd in Hy, Hz |- *.
    rewrite -!/(minus _ _).
    eapply Rle_trans.
    2: apply Rmult_le_compat_l.
    2: apply Rlt_le, eps.
    2: apply sqrt_plus_sqr.
    simpl.
    rewrite !Rabs_pos_eq ; try by apply abs_ge_0.
    replace (pos eps)%R with ((eps / 2) * 2)%R by field.
    rewrite Rmult_assoc.
    eapply Rle_trans.
    2: apply Rmult_le_compat_l.
    2: apply Rlt_le, is_pos_div_2.
    2: by apply Rplus_le_Rmax.

    set v := minus (scal _ _) _.
    replace v with (plus (scal (minus z1 y1) z2) (scal y1 (minus z2 y2))).
    Focus 2.
      rewrite /v /minus scal_distr_r scal_distr_l -!plus_assoc.
      apply f_equal.
      rewrite scal_opp_r.
      apply (plus_reg_r (scal y1 y2)) ;
      rewrite plus_assoc -plus_assoc.
      rewrite plus_opp_l plus_zero_r.
      rewrite scal_opp_l.
      by apply plus_opp_l.
      clear v.
      set v := minus (plus _ _) _.
    replace v with (plus (scal (minus z1 y1) (minus z2 x2)) (scal (minus y1 x1) (minus z2 y2))).
    eapply Rle_trans.
    apply norm_triangle.
    eapply Rle_trans.
    apply Rplus_le_compat ; simpl ; apply norm_scal.
    rewrite Rmult_plus_distr_l.
    rewrite Rmult_comm.
    apply Rplus_le_compat ; apply Rmult_le_compat_r.
    by apply abs_ge_0.
    eapply Rle_trans.
    by apply Rlt_le, Hz.
    eapply Rle_trans.
    apply Rmult_le_compat_l.
    by apply Rlt_le, M.
    apply Rmin_r.
    apply Req_le ; field.
    by apply Rgt_not_eq, M.
    by apply norm_ge_0.
    eapply Rle_trans.
    by apply Rlt_le, Hy.
    apply Rmin_l.
    rewrite /v /minus !scal_distr_l !scal_distr_r !opp_plus !scal_opp_r !scal_opp_l !opp_opp -!plus_assoc.
    apply f_equal, f_equal.
    rewrite plus_comm -!plus_assoc plus_comm -!plus_assoc.
    apply f_equal.
    rewrite plus_comm -!plus_assoc.
    apply f_equal.
    by rewrite plus_comm -!plus_assoc.
    by apply norm_ge_0.
Qed.

Lemma ex_filterdiff_scal : forall {F} {FF : ProperFilter F} (x : K * V), 
  is_filter_lim F x ->
  (forall (n m : K), mult n m = mult m n) ->
  ex_filterdiff (fun t : K * V => scal (fst t) (snd t)) F.
Proof.
  eexists.
  by apply (filterdiff_scal x).
Qed.

Lemma filterdiff_scal_l : forall {F} {FF : Filter F} (x : V), 
  filterdiff (fun k : K => scal k x) F (fun k => scal k x).
Proof.
  move => F FF x.
  apply filterdiff_linear.
  by apply is_linear_scal_l.
Qed.

Lemma ex_filterdiff_scal_l : forall {F} {FF : Filter F} (x : V), 
  ex_filterdiff (fun k : K => scal k x) F.
Proof.
  eexists.
  by apply (filterdiff_scal_l x).
Qed.

Lemma filterdiff_scal_r : forall {F} {FF : Filter F} (k : K), 
  (forall (n m : K), mult n m = mult m n) ->
  filterdiff (fun x : V => scal k x) F (fun x => scal k x).
Proof.
  move => F FF x Hcomm.
  apply filterdiff_linear.
  by apply is_linear_scal_r.
Qed.

Lemma ex_filterdiff_scal_r : forall {F} {FF : Filter F} (k : K), 
  (forall (n m : K), mult n m = mult m n) ->
  ex_filterdiff (fun x : V => scal k x) F.
Proof.
  eexists.
  by apply (filterdiff_scal_r k).
Qed.

End Operations.

Lemma filterdiff_mult {K : AbsRing} :
 forall {F} {FF : ProperFilter F} (x : K * K), 
  is_filter_lim F x ->
  (forall (n m : K), mult n m = mult m n) ->
  filterdiff (fun t : K * K => mult (fst t) (snd t)) F
    (fun t => plus (mult (fst t) (snd x)) (mult (fst x) (snd t))).
Proof.
  intros.
  generalize (filterdiff_scal x H H0) ; by simpl.
Qed.

Lemma ex_filterdiff_mult {K : AbsRing} :
 forall {F} {FF : ProperFilter F} (x : K * K), 
  is_filter_lim F x ->
  (forall (n m : K), mult n m = mult m n) ->
  ex_filterdiff (fun t : K * K => mult (fst t) (snd t)) F.
Proof.
  eexists.
  by apply (filterdiff_mult x).
Qed.

(** Composed operations *)

Section Operations_fct.

Context {K : AbsRing} {U V : NormedModule K}.

Lemma filterdiff_opp_fct {F} {FF : Filter F} (f lf : U -> V) :
  filterdiff f F lf ->
  filterdiff (fun t => opp (f t)) F (fun t => opp (lf t)).
Proof.
  intro Df.
  apply filterdiff_compose.
  by [].
  by apply filterdiff_opp.
Qed.
Lemma ex_filterdiff_opp_fct {F} {FF : Filter F} (f : U -> V) :
  ex_filterdiff f F ->
  ex_filterdiff (fun t => opp (f t)) F.
Proof.
  intros [lf Df].
  eexists.
  apply filterdiff_opp_fct ; eassumption.
Qed.

Lemma filterdiff_plus_fct {F} {FF : Filter F} (f g : U -> V) (lf lg : U -> V) : 
  filterdiff f F lf -> filterdiff g F lg ->
  filterdiff (fun u => plus (f u) (g u)) F (fun u => plus (lf u) (lg u)).
Proof.
  intros Df Dg.
  apply filterdiff_compose_2.
  by [].
  by [].
  by apply filterdiff_plus.
Qed.
Lemma ex_filterdiff_plus_fct {F} {FF : Filter F} (f g : U -> V) : 
  ex_filterdiff f F -> ex_filterdiff g F ->
  ex_filterdiff (fun u => plus (f u) (g u)) F.
Proof.
  intros [lf Df] [lg Dg].
  eexists.
  apply filterdiff_plus_fct ; eassumption.
Qed.

Lemma filterdiff_minus_fct {F} {FF : Filter F} (f g : U -> V) (lf lg : U -> V) : 
  filterdiff f F lf -> filterdiff g F lg ->
  filterdiff (fun u => minus (f u) (g u)) F (fun u => minus (lf u) (lg u)).
Proof.
  intros Df Dg.
  apply filterdiff_compose_2.
  by [].
  by [].
  by apply filterdiff_minus.
Qed.
Lemma ex_filterdiff_minus_fct {F} {FF : Filter F} (f g : U -> V) : 
  ex_filterdiff f F -> ex_filterdiff g F ->
  ex_filterdiff (fun u => minus (f u) (g u)) F.
Proof.
  intros [lf Df] [lg Dg].
  eexists.
  apply filterdiff_minus_fct ; eassumption.
Qed.

Lemma filterdiff_scal_fct x (f : U -> K) (g : U -> V) lf lg :
  (forall (n m : K), mult n m = mult m n) ->
  filterdiff f (locally x) lf -> filterdiff g (locally x) lg ->
  filterdiff (fun t => scal (f t) (g t)) (locally x)
    (fun t => plus (scal (lf t) (g x)) (scal (f x) (lg t))).
Proof.
  intros Hcomm Df Dg.
  apply (filterdiff_compose'_2 f g scal x lf lg (fun k v => plus (scal k (g x)) (scal (f x) v))) => //.
  by apply (filterdiff_scal (f x, g x)).
Qed.
Lemma ex_filterdiff_scal_fct x (f : U -> K) (g : U -> V) :
  (forall (n m : K), mult n m = mult m n) ->
  ex_filterdiff f (locally x) -> ex_filterdiff g (locally x) ->
  ex_filterdiff (fun t => scal (f t) (g t)) (locally x).
Proof.
  intros Hcomm [lf Df] [lg Dg].
  eexists.
  apply (filterdiff_scal_fct x) ; eassumption.
Qed.

Lemma filterdiff_scal_l_fct : forall {F} {FF : Filter F} (x : V) (f : U -> K) lf,
  filterdiff f F lf ->
  filterdiff (fun u => scal (f u) x) F (fun u => scal (lf u) x).
Proof.
  move => F FF x f lf Df.
  apply (filterdiff_compose f (fun k => scal k x) lf (fun k => scal k x)).
  by [].
  apply filterdiff_linear.
  by apply is_linear_scal_l.
Qed.
Lemma ex_filterdiff_scal_l_fct : forall {F} {FF : Filter F} (x : V) (f : U -> K),
  ex_filterdiff f F ->
  ex_filterdiff (fun u => scal (f u) x) F.
Proof.
  intros F FF x f [lf Df].
  eexists.
  apply (filterdiff_scal_l_fct x) ; eassumption.
Qed.

Lemma filterdiff_scal_r_fct : forall {F} {FF : Filter F} (k : K) (f lf : U -> V), 
  (forall (n m : K), mult n m = mult m n) ->
  filterdiff f F lf ->
  filterdiff (fun x => scal k (f x)) F (fun x => scal k (lf x)).
Proof.
  move => F FF k f lf Hcomm Df.
  apply (filterdiff_compose f (fun x => scal k x) lf (fun x => scal k x)).
  by [].
  apply filterdiff_linear.
  by apply is_linear_scal_r.
Qed.
Lemma ex_filterdiff_scal_r_fct : forall {F} {FF : Filter F} (k : K) (f : U -> V), 
  (forall (n m : K), mult n m = mult m n) ->
  ex_filterdiff f F ->
  ex_filterdiff (fun x => scal k (f x)) F.
Proof.
  move => F FF k f Hcomm [lf Df].
  eexists.
  apply (filterdiff_scal_r_fct k) ; eassumption.
Qed.

End Operations_fct.

Lemma filterdiff_mult_fct {K : AbsRing} {U : NormedModule K}
  (f g : U -> K) x (lf lg : U -> K) :
  (forall (n m : K), mult n m = mult m n) ->
  filterdiff f (locally x) lf -> filterdiff g (locally x) lg
  -> filterdiff (fun t => mult (f t) (g t)) (locally x) 
    (fun t => plus (mult (lf t) (g x)) (mult (f x) (lg t))).
Proof.
  intros.
  by apply @filterdiff_scal_fct.
Qed.

Lemma ex_filterdiff_mult_fct {K : AbsRing} {U : NormedModule K}
  (f g : U -> K) x :
  (forall (n m : K), mult n m = mult m n) ->
  ex_filterdiff f (locally x) -> ex_filterdiff g (locally x)
  -> ex_filterdiff (fun t => mult (f t) (g t)) (locally x).
Proof.
  intros Hcomm [lf Df] [lg Dg].
  eexists.
  apply @filterdiff_mult_fct ; eassumption.
Qed.

(** * Differentiability in 1 dimentional space *)

Section Derive.

Context {K : AbsRing} {V : NormedModule K}.

Definition filterderive (f : K -> V) F (l : V) :=
  forall x, is_filter_lim F x ->
  is_domin F (fun y : K => minus y x) (fun y => minus (minus (f y) (f x)) (scal (minus y x) l)).

Definition ex_filterderive (f : K -> V) F :=
  exists l, filterderive f F l.

Lemma filterdiff_derive {F} {FF : Filter F} (f : K -> V) (l : V) :
  filterdiff f F (fun y => scal y l) <-> filterderive f F l.
Proof.
  split.
  - case => Hl Df x Hx.
    by apply Df.
  - move => Df ; split => [ | x Hx].
    by apply is_linear_scal_l.
    by apply Df.
Qed.

Lemma filterderive_diff {F} {FF : Filter F} (f : K -> V) (l : K -> V) :
    (is_linear l /\ filterderive f F (l one)) <-> filterdiff f F l.
Proof.
  split ; case => Hl Df ; split => // x Hx.
  - apply domin_rw_r with (2 := Df x Hx).
    apply equiv_ext_loc.
    apply filter_imp with (2 := filter_true) => y /= _.
    apply f_equal.
    rewrite -linear_scal //=.
    apply f_equal, mult_one_r.
  - apply domin_rw_r with (2 := Df x Hx).
    apply equiv_ext_loc.
    apply filter_imp with (2 := filter_true) => y /= _.
    apply f_equal.
    rewrite -linear_scal //=.
    apply f_equal, sym_eq, mult_one_r.
Qed.

Lemma ex_filterdiff_derive {F} {FF : Filter F} (f : K -> V) :
  ex_filterdiff f F <-> ex_filterderive f F.
Proof.
  split ; intros [l Hf] ; eexists.
  apply filterderive_diff.
  exact Hf.
  apply filterdiff_derive.
  exact Hf.
Qed.

Definition is_derive (f : K -> V) (x : K) (l : V) :=
  filterdiff f (locally x) (fun y => scal y l).

Definition ex_derive (f : K -> V) (x : K) :=
  exists l : V, is_derive f x l.

Lemma ex_derive_filterdiff :
  forall (f : K -> V) (x : K),
  ex_derive f x <-> ex_filterdiff f (locally x).
Proof.
intros f x.
split ; case => d Df.
- eexists.
  exact Df.
- exists (d one).
  split.
  apply is_linear_scal_l.
  simpl => t Ht.
  destruct Df as [Ld Df].
  simpl in Df.
  apply domin_rw_r with (2 := Df t Ht).
  apply equiv_ext_loc.
  apply filter_imp with (2 := filter_true) => y /= _.
  apply f_equal.
  rewrite -linear_scal //=.
  apply f_equal, sym_eq, mult_one_r.
Qed.

End Derive.

(** * Definitions on [R] *)

Definition Derive (f : R -> R) (x : R) := real (Lim (fun h => (f (x+h) - f x)/h) 0).

Lemma is_derive_Reals (f : R -> R) (x l : R) :
  derivable_pt_lim f x l <-> is_derive f x l.
Proof.
  split => Hf.
  + split.
    apply @is_linear_scal_l.
    move => y Hy eps.
    rewrite -(is_filter_lim_locally_unique_R _ _ Hy) ; clear y Hy.
    case: (Hf eps (cond_pos _)) => {Hf} d Hf.
    exists d => y /= Hy.
    case: (Req_dec y x) => Hxy.
    rewrite Hxy /norm /scal /= /abs /minus /plus /opp /mult /=.
    ring_simplify (f x + - f x + - ((x + - x) * l)).
    ring_simplify (x + - x).
    rewrite Rabs_R0 Rmult_0_r.
    by apply Rle_refl.
    apply Rle_div_l.
    apply Rabs_pos_lt.
    by apply Rminus_eq_contra.
    rewrite -Rabs_div.
    2: by apply Rminus_eq_contra.
    rewrite /scal /= /minus /plus /opp /mult /=.
    replace ((f y + - f x + - ((y + - x) * l)) / (y + - x))
      with ((f (x + (y-x)) - f x) / (y-x) - l).
    2: ring_simplify (x + (y - x)) ; field ; by apply Rminus_eq_contra.
    apply Rlt_le, Hf.
    by apply Rminus_eq_contra.
    by [].
  + move => e He.
    destruct Hf as [_ Hf].
    specialize (Hf x (fun P H => H)).
    destruct (Hf (pos_div_2 (mkposreal _ He))) as [delta Hd].
    exists delta => h Hh0 Hh.
    apply Rle_lt_trans with (e / 2).
    simpl in Hd.
    replace ((f (x + h) - f x) / h - l) with 
      ((f (x + h) + - f x + - ((x + h + - x) * l)) / (x + h + - x)).
    2: by field.
    rewrite Rabs_div.
    2: by ring_simplify (x + h + - x).
    apply Rle_div_l.
    now ring_simplify (x + h + - x) ; apply Rabs_pos_lt.
    apply Hd.
    rewrite /ball /= /AbsRing_ball /= /abs /minus /plus /opp /=.
    by ring_simplify (x + h + - x).
    apply Rlt_div_l, Rminus_lt_0 ; ring_simplify.
    by apply Rlt_0_2.
    by [].
Qed.

(*
Lemma ex_filterdiff_Reals (f : R -> R) (x : R) :
  ex_derive f x <-> ex_filterdiff f (locally x).
Proof.
  split ; intros [l Hf].
  eexists.
  apply filterdiff_Reals.
  by apply Hf.
  exists (l one).
  apply filterdiff_Reals.
  apply filterdiff_ext_lin with (1 := Hf).
  move => y.
  rewrite -(linear_scal l (proj1 Hf) y one).
  apply f_equal, sym_eq, Rmult_1_r.
Qed.
*)

(** Derive is correct *)

Lemma is_derive_unique f x l :
  is_derive f x l -> Derive f x = l.
Proof.
  intros H.
  apply (@f_equal _ _ real _ l).
  apply is_lim_unique.
  apply is_lim_spec.
  apply is_derive_Reals in H.
  intros eps.
  destruct (H eps (cond_pos _)) as [d Hd].
  exists d => h.
  rewrite /ball /= /AbsRing_ball /= /minus /plus /opp /= Ropp_0 Rplus_0_r.
  intros Hu Zu.
  now apply Hd.
Qed.

Lemma Derive_correct f x :
  ex_derive f x -> is_derive f x (Derive f x).
Proof.
    intros (l,H).
  cut (Derive f x = l).
    intros ; rewrite H0 ; apply H.
  apply is_derive_unique, H.
Qed.

(** Equivalence with standard library Reals *)

Lemma ex_derive_Reals_0 (f : R -> R) (x : R) :
  ex_derive f x -> derivable_pt f x.
Proof.
  move => Hf.
  apply Derive_correct in Hf.
  apply is_derive_Reals in Hf.
  by exists (Derive f x).
Qed.

Lemma ex_derive_Reals_1 (f : R -> R) (x : R) :
  derivable_pt f x -> ex_derive f x.
Proof.
  case => l Hf.
  exists l.
  now apply is_derive_Reals.
Qed.

Lemma Derive_Reals (f : R -> R) (x : R) (pr : derivable_pt f x) :
  derive_pt f x pr = Derive f x.
Proof.
  apply sym_eq, is_derive_unique.
  case: pr => /= l Hf.
  now apply is_derive_Reals.
Qed.

(** A tactic to simplify interactive proofs of differentiability *)

Ltac search_derive := let l := fresh "l" in
evar (l : R) ;
match goal with
  | |- Derive _ _ = ?lu => apply is_derive_unique ; replace lu with l ; [ | unfold l]
  | |- derivable_pt_lim _ _ ?lu => replace lu with l ; [ | unfold l]
end.

(** Extensionality *)

Section Extensionality.

Context {K : AbsRing} {V : NormedModule K}.

Lemma is_derive_ext_loc :
  forall (f g : K -> V) (x : K) (l : V),
  locally x (fun t : K => f t = g t) ->
  is_derive f x l -> is_derive g x l.
Proof.
intros f g x l Heq Hf.
now apply (filterdiff_ext_locally f g _ _ Heq).
Qed.

Lemma ex_derive_ext_loc :
  forall (f g : K -> V) (x : K),
  locally x (fun t : K => f t = g t) ->
  ex_derive f x -> ex_derive g x.
Proof.
intros f g x Hfg (l,Hf).
exists l.
apply: is_derive_ext_loc Hfg Hf.
Qed.

Lemma is_derive_ext :
  forall (f g : K -> V) (x : K) (l : V),
  (forall t : K, f t = g t) ->
  is_derive f x l -> is_derive g x l.
Proof.
intros f g x l Heq Hf.
apply: filterdiff_ext_locally Hf.
by apply filter_forall.
Qed.

Lemma ex_derive_ext :
  forall (f g : K -> V) (x : K),
  (forall t : K, f t = g t) ->
  ex_derive f x -> ex_derive g x.
Proof.
intros f g x Heq [l Hf].
exists l ; move: Hf ; by apply is_derive_ext.
Qed.

End Extensionality.

Lemma Derive_ext_loc :
  forall f g x,
  locally x (fun t => f t = g t) ->
  Derive f x = Derive g x.
Proof.
intros f g x Hfg.
rewrite /Derive /Lim.
apply f_equal, Lim_seq_ext_loc.
apply (filterlim_Rbar_loc_seq 0 (fun h => (f (x + h) - f x) / h = (g (x + h) - g x) / h)).
apply (filter_imp (fun h => f (x + h) = g (x + h))).
intros h ->.
by rewrite (locally_singleton _ _ Hfg).
destruct Hfg as [eps He].
exists eps => h H Hh.
apply He.
rewrite /ball /= /AbsRing_ball /= /minus /plus /opp /=.
now replace (x + h + - x) with (h - 0) by ring.
Qed.

Lemma Derive_ext :
  forall f g x,
  (forall t, f t = g t) ->
  Derive f x = Derive g x.
Proof.
intros f g x Hfg.
apply Derive_ext_loc.
by apply filter_forall.
Qed.

(** * Operations *)
(** Constant functions *)

Section Const.

Context {K : AbsRing} {V : NormedModule K}.

Lemma is_derive_const :
  forall (a : V) (x : K), is_derive (fun _ : K => a) x zero.
Proof.
intros a x.
apply filterdiff_ext_lin with (fun y : K => zero).
apply filterdiff_const.
intros y.
apply sym_eq.
apply: scal_zero_r.
Qed.

Lemma ex_derive_const :
  forall (a : V) (x : K), ex_derive (fun _ => a) x.
Proof.
intros a x.
eexists.
apply is_derive_const.
Qed.

End Const.

Lemma Derive_const :
  forall (a x : R),
  Derive (fun _ => a) x = 0.
Proof.
intros a x.
apply is_derive_unique.
apply: is_derive_const.
Qed.

(** Identity function *)

Section Id.

Context {K : AbsRing}.

Lemma is_derive_id :
  forall x : K, is_derive (fun t : K => t) x one.
Proof.
intros x.
apply filterdiff_ext_lin with (fun t : K => t).
apply filterdiff_id.
rewrite /scal /=.
intros y.
apply sym_eq, mult_one_r.
Qed.

Lemma ex_derive_id :
  forall x : K, ex_derive (fun t : K => t) x.
Proof.
intros x.
eexists.
apply is_derive_id.
Qed.

End Id.

Lemma Derive_id :
  forall x,
  Derive id x = 1.
Proof.
intros x.
apply is_derive_unique.
apply: is_derive_id.
Qed.

(** ** Additive operators *)
(** Opposite of functions *)

Section Opp.

Context {K : AbsRing}.

Lemma is_derive_opp :
  forall (x : K), is_derive opp x (opp one).
Proof.
intros x.
apply filterdiff_ext_lin with opp.
apply: filterdiff_opp.
intros y.
by rewrite scal_opp_r /scal /= mult_one_r.
Qed.

Lemma ex_derive_opp :
  forall (x : K), ex_derive opp x.
Proof.
intros x.
eexists.
apply is_derive_opp.
Qed.

Context {V : NormedModule K}.

Lemma is_derive_opp_fct :
  forall (f : K -> V) (x : K) (l : V),
  is_derive f x l ->
  is_derive (fun x => opp (f x)) x (opp l).
Proof.
intros f x l Df.
apply filterdiff_ext_lin with (fun t : K => opp (scal t l)).
apply filterdiff_compose' with (1 := Df).
apply filterdiff_opp.
intros y.
apply sym_eq.
apply: scal_opp_r.
Qed.

Lemma ex_derive_opp_fct :
  forall (f : K -> V) (x : K),
  ex_derive f x ->
  ex_derive (fun x => opp (f x)) x.
Proof.
intros f x [df Df].
eexists.
apply is_derive_opp_fct.
exact Df.
Qed.

End Opp.

Lemma Derive_opp_fct :
  forall f x,
  Derive (fun x => - f x) x = - Derive f x.
Proof.
intros f x.
unfold Derive, Lim.
rewrite /Rbar_loc_seq.
rewrite -Rbar.Rbar_opp_real.
rewrite -Lim_seq_opp.
apply f_equal, Lim_seq_ext => n.
rewrite -Ropp_mult_distr_l_reverse.
apply (f_equal (fun v => v / _)).
ring.
Qed.

Lemma Derive_opp :
  forall x,
  Derive (fun x => - x) x = -1.
Proof.
intros x.
by rewrite Derive_opp_fct Derive_id.
Qed.

(** Addition of functions *)

Section Plus.

Context {K : AbsRing} {V : NormedModule K}.

Lemma is_derive_plus :
  forall (f g : K -> V) (x : K) (df dg : V),
  is_derive f x df ->
  is_derive g x dg ->
  is_derive (fun x => plus (f x) (g x)) x (plus df dg).
Proof.
intros f g x df dg Df Dg.
eapply filterdiff_ext_lin.
apply filterdiff_plus_fct ; try eassumption.
simpl => y.
by rewrite scal_distr_l.
Qed.

Lemma ex_derive_plus :
  forall (f g : K -> V) (x : K),
  ex_derive f x -> ex_derive g x ->
  ex_derive (fun x => plus (f x) (g x)) x.
Proof.
intros f g x [df Df] [dg Dg].
exists (plus df dg).
now apply is_derive_plus.
Qed.

Lemma is_derive_sum_n :
  forall (f : nat -> K -> V) (n : nat) (x : K) (d : nat -> V),
  (forall k, (k <= n)%nat -> is_derive (f k) x (d k)) ->
  is_derive (fun y => sum_n (fun k => f k y) n) x (sum_n d n).
Proof.
  intros f n x d.
  elim: n => /= [ | n IH] Hf.
  by apply (Hf O).
  apply is_derive_plus.
  apply IH => k Hk.
  by apply Hf, le_trans with (1 := Hk), le_n_Sn.
  by apply Hf.
Qed.

Lemma ex_derive_sum_n :
  forall (f : nat -> K -> V) (n : nat) (x : K),
  (forall k, (k <= n)%nat -> ex_derive (f k) x) ->
  ex_derive (fun y => sum_n (fun k => f k y) n) x.
Proof.
  intros f n x.
  elim: n => /= [ | n IH] Hf.
  by apply (Hf O).
  apply ex_derive_plus.
  apply IH => k Hk.
  by apply Hf, le_trans with (1 := Hk), le_n_Sn.
  by apply Hf.
Qed.

End Plus.

Lemma Derive_plus :
  forall f g x, ex_derive f x -> ex_derive g x ->
  Derive (fun x => f x + g x) x = Derive f x + Derive g x.
Proof.
intros f g x Df Dg.
apply is_derive_unique.
apply: is_derive_plus ;
  now apply Derive_correct.
Qed.

Lemma Derive_sum_n (f : nat -> R -> R) (n : nat) (x : R) :
  (forall k, (k <= n)%nat -> ex_derive (f k) x) ->
  Derive (fun y => sum_n (fun k => f k y) n) x = sum_n (fun k => Derive (f k) x) n.
Proof.
  move => Hf.
  apply is_derive_unique.
  apply: is_derive_sum_n.
  move => k Hk.
  by apply Derive_correct, Hf.
Qed.

(** Difference of functions *)

Section Minus.

Context {K : AbsRing} {V : NormedModule K}.

Lemma is_derive_minus :
  forall (f g : K -> V) (x : K) (df dg : V),
  is_derive f x df ->
  is_derive g x dg ->
  is_derive (fun x => minus (f x) (g x)) x (minus df dg).
Proof.
intros f g x df dg Df Dg.
eapply filterdiff_ext_lin.
apply filterdiff_minus_fct ; try eassumption.
simpl => y.
by rewrite scal_distr_l scal_opp_r.
Qed.

Lemma ex_derive_minus :
  forall (f g : K -> V) (x : K),
  ex_derive f x -> ex_derive g x ->
  ex_derive (fun x => minus (f x) (g x)) x.
Proof.
intros f g x [df Df] [dg Dg].
exists (minus df dg).
now apply is_derive_minus.
Qed.

End Minus.

Lemma Derive_minus :
  forall f g x, ex_derive f x -> ex_derive g x ->
  Derive (fun x => f x - g x) x = Derive f x - Derive g x.
Proof.
intros f g x Df Dg.
apply is_derive_unique.
apply: is_derive_minus ;
  now apply Derive_correct.
Qed.

(** ** Multiplicative operators *)
(** Multiplication of functions *)

Lemma is_derive_inv_fct (f : R -> R) (x l : R) :
  is_derive f x l -> f x <> 0
    -> is_derive (fun y => / f y) x (-l/(f x)^2).
Proof.
  move => Hf Hl.
  eapply filterdiff_ext_lin.
  apply filterdiff_ext with (fun y => 1/f y).
  move => t ; by rewrite /Rdiv Rmult_1_l.
  apply is_derive_Reals.
  apply derivable_pt_lim_div.
  apply derivable_pt_lim_const.
  apply is_derive_Reals.
  exact Hf.
  exact Hl.
  simpl => y ; apply f_equal.
  rewrite /= /Rsqr ; by field.
Qed.

Lemma ex_derive_inv_fct (f : R -> R) (x : R) :
  ex_derive f x -> f x <> 0
    -> ex_derive (fun y => / f y) x.
Proof.
  case => l Hf Hl.
  exists (-l/(f x)^2).
  by apply is_derive_inv_fct.
Qed.

Lemma Derive_inv_fct (f : R -> R) (x : R) :
  ex_derive f x -> f x <> 0
    -> Derive (fun y => / f y) x = - Derive f x / (f x) ^ 2.
Proof.
  move/Derive_correct => Hf Hl.
  apply is_derive_unique.
  by apply is_derive_inv_fct.
Qed.

Lemma ex_derive_scal_fct :
  forall f k x, ex_derive f x ->
  ex_derive (fun x => k * f x) x.
Proof.
intros f k x (df,Df).
exists (k * df).
now apply is_derive_Reals, derivable_pt_lim_scal, is_derive_Reals.
Qed.

Lemma Derive_scal_fct :
  forall f k x,
  Derive (fun x => k * f x) x = k * Derive f x.
Proof.
intros f k x.
unfold Derive, Lim.
have H : (forall x, k * Rbar.real x = Rbar.real (Rbar.Rbar_mult (Rbar.Finite k) x)).
  case: (Req_dec k 0) => [-> | Hk].
  case => [l | | ] //= ; rewrite Rmult_0_l.
  case: Rle_dec (Rle_refl 0) => //= H _.
  case: Rle_lt_or_eq_dec (Rlt_irrefl 0) => //= _ _.
  case: Rle_dec (Rle_refl 0) => //= H _.
  case: Rle_lt_or_eq_dec (Rlt_irrefl 0) => //= _ _.
  case => [l | | ] //= ; rewrite Rmult_0_r.
  case: Rle_dec => //= H.
  case: Rle_lt_or_eq_dec => //=.
  case: Rle_dec => //= H.
  case: Rle_lt_or_eq_dec => //=.
rewrite H.
rewrite -Lim_seq_scal_l.
apply f_equal, Lim_seq_ext => n.
rewrite -Rmult_assoc.
apply (f_equal (fun v => v / _)).
ring.
Qed.

Lemma is_derive_scal_r_fct (f : R -> R) (k x l : R) :
  is_derive f x l ->
  is_derive (fun x => f x * k) x (l*k).
Proof.
  move => Hf.
  eapply filterdiff_ext_lin.
  apply @filterdiff_scal_l_fct ; try by apply locally_filter.
  exact Hf.
  simpl => y.
  apply Rmult_assoc.
Qed.

Lemma ex_derive_scal_r_fct (f : R -> R) (k x : R) :
  ex_derive f x ->
  ex_derive (fun x => f x * k) x.
Proof.
  case => l Hf.
  exists (l * k).
  by apply is_derive_scal_r_fct.
Qed.

Lemma Derive_scal_r_fct (f : R -> R) (k x : R) :
  Derive (fun x => f x * k) x = Derive f x * k.
Proof.
  rewrite Rmult_comm -Derive_scal_fct.
  apply Derive_ext => t ; by apply Rmult_comm.
Qed.

Lemma ex_derive_mult_fct (f g : R -> R) (x : R) :
  ex_derive f x -> ex_derive g x
    -> ex_derive (fun x => f x * g x) x.
Proof.
  move => [d1 H1] [d2 H2].
  exists (d1 * g x + f x * d2).
  apply is_derive_Reals, derivable_pt_lim_mult ;
    now apply is_derive_Reals.
Qed.

Lemma Derive_mult_fct (f g : R -> R) (x : R) :
  ex_derive f x -> ex_derive g x
    -> Derive (fun x => f x * g x) x = Derive f x * g x + f x * Derive g x.
Proof.
  move => H1 H2.
  apply is_derive_unique.
  apply is_derive_Reals, derivable_pt_lim_mult ;
    now apply is_derive_Reals, Derive_correct.
Qed.

Lemma is_derive_pow_fct (f : R -> R) (n : nat) (x : R) (l : R) :
  is_derive f x l -> is_derive (fun x => (f x)^n) x (INR n * l * (f x)^(pred n)).
Proof.
  move => H.
  rewrite (Rmult_comm _ l) Rmult_assoc Rmult_comm.
  apply is_derive_Reals.
  apply (derivable_pt_lim_comp f (fun x => x^n)).
  now apply is_derive_Reals.
  by apply derivable_pt_lim_pow.
Qed.

Lemma ex_derive_pow_fct (f : R -> R) (n : nat) (x : R) :
  ex_derive f x -> ex_derive (fun x => (f x)^n) x.
Proof.
  case => l H.
  exists (INR n * l * (f x)^(pred n)).
  by apply is_derive_pow_fct.
Qed.

Lemma Derive_pow (f : R -> R) (n : nat) (x : R) :
  ex_derive f x -> Derive (fun x => (f x)^n) x = (INR n * Derive f x * (f x)^(pred n)).
Proof.
  move => H.
  apply is_derive_unique.
  apply is_derive_pow_fct.
  by apply Derive_correct.
Qed.

Lemma ex_derive_div_fct (f g : R -> R) (x : R) :
  ex_derive f x -> ex_derive g x -> g x <> 0
    -> ex_derive (fun y => f y / g y) x.
Proof.
  move => Hf Hg Hl.
  apply ex_derive_mult_fct.
  apply Hf.
  by apply ex_derive_inv_fct.
Qed.

Lemma Derive_div_fct (f g : R -> R) (x : R) :
  ex_derive f x -> ex_derive g x -> g x <> 0
    -> Derive (fun y => f y / g y) x = (Derive f x * g x - f x * Derive g x) / (g x) ^ 2.
Proof.
  move => Hf Hg Hl.
  search_derive.
  apply is_derive_Reals, derivable_pt_lim_div ;
    try now apply is_derive_Reals, Derive_correct.
  by apply Hl.
  rewrite /Rsqr ; by field.
Qed.

(** Inverse function *)

Lemma is_derive_inv (x : R) :
  x <> 0
    -> is_derive (fun y => / y) x (-/x^2).
Proof.
  move => Hf.
  evar (l : R).
  replace (- / x ^ 2) with l.
  apply is_derive_inv_fct with (2 := Hf).
  apply is_derive_id.
  rewrite /l /one /= /Rdiv ; ring.
Qed.

Lemma ex_derive_inv (x : R) :
  x <> 0
    -> ex_derive (fun y => / y) x.
Proof.
  move => Hf.
  exists (-/x^2).
  by apply is_derive_inv.
Qed.

Lemma Derive_inv (x : R) :
  x <> 0
    -> Derive (fun y => / y) x = - / x ^ 2.
Proof.
  move => Hl.
  apply is_derive_unique.
  by apply is_derive_inv.
Qed.

(** Composition of functions *)

Lemma ex_derive_comp (f g : R -> R) (x : R) :
  ex_derive f (g x) -> ex_derive g x
    -> ex_derive (fun x => f (g x)) x.
Proof.
intros (df,Df) (dg,Dg).
exists (df * dg).
apply is_derive_Reals, derivable_pt_lim_comp ;
  now apply is_derive_Reals.
Qed.

Lemma Derive_comp (f g : R -> R) (x : R) :
  ex_derive f (g x) -> ex_derive g x
    -> Derive (fun x => f (g x)) x = Derive f (g x) * Derive g x.
Proof.
intros Df Dg.
apply is_derive_unique.
apply is_derive_Reals, derivable_pt_lim_comp ;
  now apply is_derive_Reals, Derive_correct.
Qed.

(** * Mean value theorem *)

Lemma MVT_gen (f : R -> R) (a b : R) :
  let a0 := Rmin a b in
  let b0 := Rmax a b in
  (forall x, a0 < x < b0 -> ex_derive f x)
  -> (forall x, a0 <= x <= b0 -> continuity_pt f x)
  -> exists c, a0 <= c <= b0 /\ f b - f a = Derive f c * (b - a).
Proof.
  move => a0 b0 Hd Hf.
  case: (Req_dec a0 b0) => Hab.
  exists a0 ; split.
  split ; by apply Req_le.
  replace b with a.
  ring.
  move: Hab ; rewrite /a0 /b0 /Rmin /Rmax ; by case: Rle_dec => Hab.
  have pr1 : forall c:R, a0 < c < b0 -> derivable_pt f c.
    move => x Hx ; exists (Derive f x).
    by apply is_derive_Reals, Derive_correct, Hd.
  have pr2 : forall c:R, a0 < c < b0 -> derivable_pt id c.
    move => x Hx ; exists 1.
    by apply derivable_pt_lim_id.
  case: (MVT f id a0 b0 pr1 pr2).
  apply Rnot_le_lt ; contradict Hab ; apply Rle_antisym.
  by apply Rcomplements.Rmin_Rmax.
  by apply Hab.
  by apply Hf.
  move => x Hx ; apply derivable_continuous, derivable_id.
  move => /= c [Hc H].
  exists c ; split.
  split ; by apply Rlt_le, Hc.
  replace (Derive f c) with (derive_pt f c (pr1 c Hc)).
  move: H ; rewrite {1 2}/id /a0 /b0 /Rmin /Rmax ;
  case: Rle_dec => Hab0 H.
  rewrite Rmult_comm H -(pr_nu _ _ (derivable_pt_id _)) derive_pt_id.
  ring.
  replace (derive_pt f c (pr1 c Hc) * (b - a))
    with (-((a - b) * derive_pt f c (pr1 c Hc)))
    by ring.
  rewrite H -(pr_nu _ _ (derivable_pt_id _)) derive_pt_id.
  ring.
  case: (pr1 c Hc) => /= l Hl.
  apply sym_eq, is_derive_unique, is_derive_Reals, Hl.
Qed.

Lemma incr_function (f : R -> R) (a b : Rbar) :
  (forall (x : R), Rbar_lt a x -> Rbar_lt x b -> ex_derive f x)
  -> ((forall (x : R), Rbar_lt a x -> Rbar_lt x b -> Derive f x > 0)
    -> (forall (x y : R), Rbar_lt a x -> x < y -> Rbar_lt y b -> f x < f y)).
Proof.
  move => Df Hf x y Hax Hxy Hyb.
  apply Rminus_lt_0.
  case: (MVT_gen f x y) => [z Hz | z Hz | c [Hc ->]].
  apply Df.
  apply Rbar_lt_le_trans with (y := Rmin x y) (2 := Rlt_le _ _ (proj1 Hz)).
  rewrite /Rmin ; case: Rle_dec (Rlt_le _ _ Hxy) => //.
  apply Rbar_le_lt_trans with (y := Rmax x y) (1 := Rlt_le _ _ (proj2 Hz)).
  rewrite /Rmax ; case: Rle_dec (Rlt_le _ _ Hxy) => //.
  apply derivable_continuous_pt.
  exists (Derive f z) ; apply is_derive_Reals, Derive_correct.
  apply Df.
  apply Rbar_lt_le_trans with (y := Rmin x y) (2 := proj1 Hz).
  rewrite /Rmin ; case: Rle_dec (Rlt_le _ _ Hxy) => //.
  apply Rbar_le_lt_trans with (y := Rmax x y) (1 := proj2 Hz).
  rewrite /Rmax ; case: Rle_dec (Rlt_le _ _ Hxy) => //.
  apply Rmult_lt_0_compat.
  apply Hf.
  apply Rbar_lt_le_trans with (y := Rmin x y) (2 := proj1 Hc).
  rewrite /Rmin ; case: Rle_dec (Rlt_le _ _ Hxy) => //.
  apply Rbar_le_lt_trans with (y := Rmax x y) (1 := proj2 Hc).
  rewrite /Rmax ; case: Rle_dec (Rlt_le _ _ Hxy) => //.
  by apply -> Rminus_lt_0.
Qed.

Lemma incr_function_le (f : R -> R) (a b : Rbar) :
  (forall (x : R), Rbar_le a x -> Rbar_le x b -> (ex_derive f) x)
  -> ((forall (x : R), Rbar_le a x -> Rbar_le x b -> Derive f x > 0)
    -> (forall (x y : R), Rbar_le a x -> x < y -> Rbar_le y b -> f x < f y)).
Proof.
  move => Df Hf x y Hax Hxy Hyb.
  apply Rminus_lt_0.
  case: (MVT_gen f x y) => [z Hz | z Hz | c [Hc ->]].
  apply Df.
  apply Rbar_le_trans with (y := Rmin x y) (2 := Rlt_le _ _ (proj1 Hz)).
  rewrite /Rmin ; case: Rle_dec (Rlt_le _ _ Hxy) => //.
  apply Rbar_le_trans with (y := Rmax x y) (1 := Rlt_le _ _ (proj2 Hz)).
  rewrite /Rmax ; case: Rle_dec (Rlt_le _ _ Hxy) => //.
  apply derivable_continuous_pt.
  exists (Derive f z) ; apply is_derive_Reals, Derive_correct.
  apply Df.
  apply Rbar_le_trans with (y := Rmin x y) (2 := proj1 Hz).
  rewrite /Rmin ; case: Rle_dec (Rlt_le _ _ Hxy) => //.
  apply Rbar_le_trans with (y := Rmax x y) (1 := proj2 Hz).
  rewrite /Rmax ; case: Rle_dec (Rlt_le _ _ Hxy) => //.
  apply Rmult_lt_0_compat.
  apply Hf.
  apply Rbar_le_trans with (y := Rmin x y) (2 := proj1 Hc).
  rewrite /Rmin ; case: Rle_dec (Rlt_le _ _ Hxy) => //.
  apply Rbar_le_trans with (y := Rmax x y) (1 := proj2 Hc).
  rewrite /Rmax ; case: Rle_dec (Rlt_le _ _ Hxy) => //.
  by apply -> Rminus_lt_0.
Qed.

Lemma MVT_cor4:
  forall (f : R -> R) a eps,
  (forall c, Rabs (c - a) <= eps -> ex_derive f c) ->
  forall b, (Rabs (b - a) <= eps) ->
  exists c, f b - f a = Derive f c * (b - a) /\ (Rabs (c - a) <= Rabs (b - a)).
Proof.
intros f a eps Hf' b.
unfold Rabs at 1 3.
case Rcase_abs; intros H1 H2.
destruct (MVT_cor2 f (Derive f) b a).
rewrite -(Rplus_0_l a).
now apply Rlt_minus_l.
intros c Hc.
apply is_derive_Reals, Derive_correct.
apply Hf'.
rewrite Rabs_left1.
apply Rle_trans with (2:=H2).
apply Ropp_le_contravar.
now apply Rplus_le_compat_r.
apply Rplus_le_reg_r with a.
now ring_simplify.
exists x; split.
rewrite -RIneq.Ropp_minus_distr (proj1 H).
ring.
rewrite Rabs_left.
apply Ropp_le_contravar.
left; now apply Rplus_lt_compat_r.
apply Rplus_lt_reg_r with a.
now ring_simplify.
destruct H1.
destruct (MVT_cor2 f (Derive f) a b).
apply Rplus_lt_reg_r with (-a).
ring_simplify.
now rewrite Rplus_comm.
intros c Hc.
apply is_derive_Reals, Derive_correct.
apply Hf'.
rewrite Rabs_right.
apply Rle_trans with (2:=H2).
now apply Rplus_le_compat_r.
apply Rle_ge; apply Rplus_le_reg_r with a.
now ring_simplify.
exists x; split.
exact (proj1 H0).
rewrite Rabs_right.
left; now apply Rplus_lt_compat_r.
apply Rle_ge; apply Rplus_le_reg_r with a.
left; now ring_simplify.
exists a.
replace b with a.
split;[ring|idtac].
rewrite /Rminus Rplus_opp_r Rabs_R0.
apply Rle_refl.
apply Rplus_eq_reg_l with (-a).
ring_simplify.
rewrite - H; ring.
Qed.

Lemma bounded_variation :
  forall h D x y,
  (forall t, Rabs (t - x) <= Rabs (y - x) -> ex_derive h t /\ (Rabs (Derive h t) <= D)) ->
  Rabs (h y - h x) <= D * Rabs (y - x).
Proof.
intros h D x y H.
destruct (MVT_cor4 h x (Rabs (y - x))) with (b := y) as [t Ht].
intros c Hc.
specialize (H c Hc).
apply H.
apply Rle_refl.
rewrite (proj1 Ht).
rewrite Rabs_mult.
apply Rmult_le_compat_r.
apply Rabs_pos.
now apply H.
Qed.

(** * Newton integration *)

Lemma fn_eq_Derive_eq: forall f g a b,
  continuity_pt f a -> continuity_pt f b ->
  continuity_pt g a -> continuity_pt g b ->
  (forall x, a < x < b -> ex_derive f x) ->
  (forall x, a < x < b -> ex_derive g x) ->
  (forall x, a < x < b -> Derive f x = Derive g x) ->
  exists C, forall x, a <= x <= b -> f x = g x + C.
Proof.
intros f g a b Cfa Cfb Cga Cgb Df Dg Hfg.
pose (h := fun x => f x - g x).
assert  (pr : forall x : R, a < x < b -> derivable_pt h x).
intros x Hx.
apply derivable_pt_minus.
eexists; apply is_derive_Reals, Derive_correct, Df, Hx.
eexists; apply is_derive_Reals, Derive_correct, Dg, Hx.
assert (constant_D_eq h (fun x : R => a <= x <= b) (h a)).
apply null_derivative_loc with (pr:=pr).
intros x Hx.
case (proj1 Hx).
case (proj2 Hx).
intros Y1 Y2.
apply derivable_continuous_pt.
apply pr; now split.
intros Y1 _; rewrite Y1.
apply continuity_pt_minus.
apply Cfb.
apply Cgb.
intros Y1; rewrite <- Y1.
apply continuity_pt_minus.
apply Cfa.
apply Cga.
intros x P.
apply trans_eq with (Derive h x).
apply sym_eq, is_derive_unique, is_derive_Reals.
now destruct (pr x P).
rewrite Derive_minus.
rewrite (Hfg _ P).
ring.
apply Df; split; apply P.
apply Dg; split; apply P.
unfold constant_D_eq in H.
exists (h a).
intros x Hx.
rewrite <- (H _ Hx).
unfold h; ring.
Qed.

(** * C1 extension *)

Lemma extension_cont (f g : R -> R) (a : R) :
  let h := fun x => match Rle_dec x a with
    | left _ => f x
    | right _ => g x
  end in
  continuity_pt f a -> continuity_pt g a
  -> f a = g a
  -> continuity_pt h a.
Proof.
  simpl => Cf Cg Heq e He.
  case: (Cf e He) => {Cf} /= df [Hdf Cf].
  case: (Cg e He) => {Cg} /= dg [Hdg Cg].
  exists (Rmin df dg) ; split.
  by apply Rmin_case.
  move => x Hx.
  case: (Rle_dec a a) (Rle_refl a) => //= _ _.
  case: Rle_dec => Hxa.
  apply Cf ; intuition.
  apply Rlt_le_trans with (1 := H0), Rmin_l.
  rewrite Heq.
  apply Cg ; intuition.
  apply Rlt_le_trans with (1 := H0), Rmin_r.
Qed.

Lemma extension_is_derive (f g : R -> R) (a l : R) :
  let h := fun x => match Rle_dec x a with
    | left _ => f x
    | right _ => g x
  end in
  is_derive f a l -> is_derive g a l
  -> f a = g a
  -> is_derive h a l.
Proof.
  simpl => Cf Cg Heq.
  apply is_derive_Reals.
  apply is_derive_Reals in Cf.
  apply is_derive_Reals in Cg.
  intros e He.
  case: (Cf e He) => {Cf} /= df Cf.
  case: (Cg e He) => {Cg} /= dg Cg.
  have Hd : 0 < Rmin df dg.
    case: (df) ; case: (dg) ; intros ; by apply Rmin_case.
  exists (mkposreal _ Hd) => /= h Hh0 Hh.
  case: (Rle_dec a a) (Rle_refl a) => //= _ _.
  case: Rle_dec => Hxa.
  apply Cf ; intuition.
  apply Rlt_le_trans with (1 := Hh), Rmin_l.
  rewrite Heq.
  apply Cg ; intuition.
  apply Rlt_le_trans with (1 := Hh), Rmin_r.
Qed.

Definition extension_C1 (f : R -> R) (a b : Rbar) (x : R) : R :=
  match Rbar_le_dec a x with
    | left _ => match Rbar_le_dec x b with
        | left _ => f x
        | right _ => f (real b) + (x - real b) * Derive f (real b)
      end
    | right _ => f (real a) + (x - real a) * Derive f (real a)
  end.

Lemma extension_C1_ext (f : R -> R) (a b : Rbar) :
  forall (x : R), Rbar_le a x -> Rbar_le x b -> (extension_C1 f a b) x = f x.
Proof.
  move => x Hax Hxb.
  rewrite /extension_C1.
  case: Rbar_le_dec => // _.
  case: Rbar_le_dec => // _.
Qed.

Lemma extension_C1_is_derive (f : R -> R) (a b : Rbar) (x l : R) :
  Rbar_le a x -> Rbar_le x b -> is_derive f x l
  -> is_derive (extension_C1 f a b) x l.
Proof.
  intros Hax' Hxb'.
  destruct (Rbar_le_lt_or_eq_dec _ _ Hax') as [Hax|Hax] ;
  destruct (Rbar_le_lt_or_eq_dec _ _ Hxb') as [Hxb|Hxb] ;
  clear Hax' Hxb' ;
  intros Hf.
(* a < x < b *)
  move: Hf ; apply @filterdiff_ext_locally.
  apply (locally_interval _ x a b) => // y Hay Hyb.
  rewrite extension_C1_ext //.
  now apply Rbar_lt_le.
  now apply Rbar_lt_le.
(* a < x = b *)
  case: b Hxb Hax Hf => [b | | ] //= Hxb Hax Hf.
  apply Rbar_finite_eq in Hxb ; rewrite Hxb in Hax Hf |- * => {x Hxb}.
  apply @filterdiff_ext_locally with (fun x : R =>
     match Rle_dec x b with
      | left _ => f x
      | right _ =>  f (real b) + (x - real b) * Derive f (real b)
    end).
  case: (Rbar_lt_locally a p_infty b) => // d Hd.
  exists d => y Hy ; case: Rle_dec => Htb ;
  rewrite /extension_C1 ; repeat case: Rbar_le_dec => // ; intros.
  contradict b0 ; apply Rbar_lt_le ; by apply Hd.
  contradict b0 ; apply Rbar_lt_le ; by apply Hd.
  apply extension_is_derive => //.
  eapply filterdiff_ext_lin.
  apply @filterdiff_plus_fct ; try by apply locally_filter.
  apply filterdiff_const.
  apply @filterdiff_scal_l_fct ; try by apply locally_filter.
  apply @filterdiff_minus_fct ; try by apply locally_filter.
  apply filterdiff_id.
  apply filterdiff_const.
  simpl => y ; rewrite (is_derive_unique _ _ _ Hf).
  rewrite /minus /plus /opp /scal /zero /= /mult /=.
  ring.
  simpl ; ring.
(* a = x < b *)
  case: a Hxb Hax Hf => [a | | ] Hxb //= Hax Hf.
  apply Rbar_finite_eq in Hax ; rewrite -Hax in Hxb Hf |- * => {x Hax}.
  apply @filterdiff_ext_locally with (fun x : R =>
     match Rle_dec x a with
      | left _ => f (real a) + (x - real a) * Derive f (real a)
      | right _ => f x
    end).
  case: (Rbar_lt_locally m_infty b a) => // d Hd.
  exists d => y Hy ; case: Rle_dec => Hat ;
  rewrite /extension_C1 ; case: Rbar_le_dec => // ; intros.
  rewrite (Rle_antisym y a) => //=.
  apply Rbar_lt_le in Hxb ; case: Rbar_le_dec => //= _ ; ring.
  case: Rbar_le_dec => // Htb.
  contradict Htb ; apply Rbar_lt_le ; by apply Hd.
  contradict b0 ; by apply Rbar_lt_le, Rnot_le_lt.
  apply extension_is_derive => //.
  eapply filterdiff_ext_lin.
  apply @filterdiff_plus_fct ; try by apply locally_filter.
  apply filterdiff_const.
  apply @filterdiff_scal_l_fct ; try by apply locally_filter.
  apply @filterdiff_minus_fct ; try by apply locally_filter.
  apply filterdiff_id.
  apply filterdiff_const.
  rewrite (is_derive_unique _ _ _ Hf) => /= y.
  rewrite /minus /plus /opp /scal /zero /= /mult /=.
  ring.
  simpl ; ring.
(* a = x = b *)
  case: a Hax => [a | | ] //= -> {a}.
  case: b Hxb => [b | | ] //= <- {b}.
  apply filterdiff_ext with (fun y => f (real x) + (y - real x) * Derive f (real x)).
  move => t ; rewrite /extension_C1.
  repeat case: Rbar_le_dec => // ; intros.
  simpl ; rewrite (Rle_antisym t x) ; try easy.
  ring.
  eapply filterdiff_ext_lin.
  apply @filterdiff_plus_fct ; try by apply locally_filter.
  apply filterdiff_const.
  apply @filterdiff_scal_l_fct ; try by apply locally_filter.
  apply @filterdiff_minus_fct ; try by apply locally_filter.
  apply filterdiff_id.
  apply filterdiff_const.
  rewrite (is_derive_unique _ _ _ Hf) => /= y.
  rewrite /minus /plus /opp /zero /scal /= /mult /=.
  ring.
Qed.

Lemma extension_C1_is_derive_a (f : R -> R) (a : R) (b : Rbar) (x : R) :
  Rbar_le a b -> x <= a -> (ex_derive f a) ->
  is_derive (extension_C1 f a b) x (Derive f a).
Proof.
  move => Hab ; case => [Hax | -> {x}] Hf ;
  apply Derive_correct in Hf.
  apply @filterdiff_ext_locally
    with (fun x => f (real a) + (x - real a) * Derive f (real a)).
  case: (Rbar_lt_locally m_infty a x) => // d Hd.
  exists d => y Hy ; rewrite /extension_C1.
  specialize (Hd _ Hy).
  case: Hd => _ Hd.
  case: Rbar_le_dec => //= ; intros.
  now elim Rle_not_lt with (1 := a0).
  rewrite /extension_C1.
  eapply filterdiff_ext_lin.
  apply @filterdiff_plus_fct ; try by apply locally_filter.
  apply filterdiff_const.
  apply @filterdiff_scal_l_fct ; try by apply locally_filter.
  apply @filterdiff_minus_fct ; try by apply locally_filter.
  apply filterdiff_id.
  apply filterdiff_const.
  simpl => y.
  rewrite /minus /plus /opp /zero /scal /= /mult /=.
  ring.
  apply extension_C1_is_derive => //.
  by right.
Qed.

Lemma extension_C1_is_derive_b (f : R -> R) (a : Rbar) (b x : R) :
  Rbar_le a b -> b <= x -> (ex_derive f b) ->
  is_derive (extension_C1 f a b) x (Derive f b).
Proof.
  move => Hab ; case => [Hxb | <- {x}] Hf ;
  apply Derive_correct in Hf.
  apply @filterdiff_ext_locally
    with (fun x => f (real b) + (x - real b) * Derive f (real b)).
  case: (Rbar_lt_locally b p_infty x) => // d Hd.
  exists d => y Hy ; rewrite /extension_C1.
  specialize (Hd _ Hy).
  case: Hd => Hd _.
  repeat case: Rbar_le_dec => //= ; intros.
  now elim Rle_not_lt with (1 := a0).
  contradict Hab ; apply Rbar_lt_not_le, Rbar_lt_trans with y => // ;
  by apply Rbar_not_le_lt.
  rewrite /extension_C1.
  repeat case: Rbar_le_dec => //= ; intros.
  eapply filterdiff_ext_lin.
  apply @filterdiff_plus_fct ; try by apply locally_filter.
  apply filterdiff_const.
  apply @filterdiff_scal_l_fct ; try by apply locally_filter.
  apply @filterdiff_minus_fct ; try by apply locally_filter.
  apply filterdiff_id.
  apply filterdiff_const.
  simpl => y.
  rewrite /minus /plus /opp /zero /scal /= /mult /=.
  ring.
  apply extension_C1_is_derive => //.
  by right.
Qed.

Lemma extension_C1_ex_derive (f : R -> R) (a b : Rbar) :
  Rbar_le a b ->
  (forall (x : R), Rbar_le a x -> Rbar_le x b -> ex_derive f x)
  -> forall (x : R), ex_derive (extension_C1 f a b) x.
Proof.
  intros Hab'.
  destruct (Rbar_le_lt_or_eq_dec _ _ Hab') as [Hab|Hab] ;
  clear Hab' ; intros Hf x.
  case: (Rbar_le_dec a x) => Hax.
  case: (Rbar_le_dec x b) => Hxb.
  case: (Hf x Hax Hxb) => {Hf} l Hf.
  exists l ; by apply extension_C1_is_derive.
  case: b Hab Hxb Hf => [b | | ] //= Hab Hxb Hf.
  exists (Derive f b).
  apply extension_C1_is_derive_b => //.
  by apply Rbar_lt_le.
  by apply Rlt_le, (Rbar_not_le_lt x b).
  apply Hf => //.
  now apply Rbar_lt_le.
  apply Rle_refl.
  now elim (Rbar_lt_not_le _ _ Hab).

  case: a Hab Hax Hf => [a | | ] // Hab Hax Hf.
  exists (Derive f a).
  apply extension_C1_is_derive_a => //.
  by apply Rbar_lt_le.
  by apply Rlt_le, Rnot_le_lt.
  apply Hf => //.
  apply Rle_refl.
  now apply Rbar_lt_le.
  by apply Rbar_not_le_lt in Hax.

  case: a Hab Hf => [a | | ] // ;
  case: b => [b | | ] // Hab Hf.
  rewrite -Hab in Hf |- * => {b Hab}.
  apply ex_derive_filterdiff.
  apply ex_filterdiff_ext with (fun y => f (real a) + (y - real a) * Derive f (real a)).
  move => t ; rewrite /extension_C1.
  repeat case: Rbar_le_dec => // ; intros.
  simpl ; rewrite (Rle_antisym t a) ; try easy.
  ring.
  apply @ex_filterdiff_plus_fct ; try by apply locally_filter.
  apply ex_filterdiff_const.
  apply @ex_filterdiff_scal_l_fct with (x := Derive f a) (f := fun u => u - a).
  by apply locally_filter.
  apply @ex_filterdiff_minus_fct.
  by apply locally_filter.
  apply ex_filterdiff_id.
  apply ex_filterdiff_const.

  apply ex_derive_filterdiff.
  apply ex_filterdiff_ext with (fun y => f 0 + (y - 0) * Derive f 0).
  move => t ; rewrite /extension_C1.
  repeat case: Rbar_le_dec => // ; intros.
  apply @ex_filterdiff_plus_fct ; try by apply locally_filter.
  apply ex_filterdiff_const.
  apply @ex_filterdiff_scal_l_fct ; try by apply locally_filter.
  apply @ex_filterdiff_minus_fct ; try by apply locally_filter.
  apply ex_filterdiff_id.
  apply ex_filterdiff_const.

  apply ex_derive_filterdiff.
  apply ex_filterdiff_ext with (fun y => f 0 + (y - 0) * Derive f 0).
  move => t ; rewrite /extension_C1.
  repeat case: Rbar_le_dec => // ; intros.
  apply @ex_filterdiff_plus_fct ; try by apply locally_filter.
  apply ex_filterdiff_const.
  apply @ex_filterdiff_scal_l_fct ; try by apply locally_filter.
  apply @ex_filterdiff_minus_fct ; try by apply locally_filter.
  apply ex_filterdiff_id.
  apply ex_filterdiff_const.
Qed.

Lemma extension_C1_Derive_cont (f : R -> R) (a b : Rbar) :
  Rbar_le a b
  -> (forall (x : R), Rbar_le a x -> Rbar_le x b -> ex_derive f x /\ continuity_pt (Derive f) x)
  -> forall x, continuity_pt (Derive (extension_C1 f a b)) x.
Proof.
  move => Hab Hf x.
  case: (Rbar_le_lt_dec a x) => Hax.
  case: (Rbar_le_lt_or_eq_dec _ _ Hax) => {Hax} Hax.
  case: (Rbar_le_lt_dec x b) => Hxb.
  case: (Rbar_le_lt_or_eq_dec _ _ Hxb) => {Hxb} Hxb.
(* a < x < b *)
  apply continuity_pt_ext_loc with (Derive f).
  apply (locally_interval _ _ _ _ Hax Hxb) => y Hay Hyb.
  apply sym_eq, is_derive_unique, extension_C1_is_derive.
  now apply Rbar_lt_le.
  now apply Rbar_lt_le.
  apply Derive_correct, Hf.
  now apply Rbar_lt_le.
  now apply Rbar_lt_le.
  apply Hf.
  now apply Rbar_lt_le.
  now apply Rbar_lt_le.
(* a < x = b *)
  case: b Hxb Hf Hab => [b | | ] // Hxb Hf Hab.
  apply Rbar_finite_eq in Hxb.
  rewrite Hxb in Hax |- * => {x Hxb Hab}.
  apply continuity_pt_ext_loc with (fun x : R =>
     match Rle_dec x b with
      | left _ => Derive f x
      | right _ =>  Derive f b
    end).
  case: (Rbar_lt_locally a p_infty b) => // d Hd.
  exists d => y Hy ; case: Rle_dec => Htb ; apply sym_eq, is_derive_unique.
  apply extension_C1_is_derive.
  now apply Rbar_lt_le, Hd.
  exact Htb.
  apply Derive_correct, Hf.
  now apply Rbar_lt_le, Hd.
  exact Htb.
  apply extension_C1_is_derive_b.
  now apply Rbar_lt_le.
  by apply Rlt_le, Rnot_le_lt.
  apply Hf.
  now apply Rbar_lt_le.
  apply Rbar_le_refl.
  apply extension_cont.
  apply Hf.
  now apply Rbar_lt_le.
  apply Rbar_le_refl.
  by apply continuity_pt_const.
  by [].
(* a <= b < x *)
  case: b Hab Hf Hxb => [b | | ] // Hab Hf Hxb.
  apply continuity_pt_ext_loc with (fun _ => Derive f b).
  apply (locally_interval _ _ b p_infty) => // y Hay Hyb.
  apply sym_eq, is_derive_unique.
  apply extension_C1_is_derive_b => //.
  by apply Rlt_le.
  apply Hf => //.
  by right.
  by apply continuity_pt_const.
  case: a Hax Hab Hf => [a | | ] Hax Hab Hf // ; try by case: Hab.
  apply continuity_pt_ext with (fun _ => Derive f 0).
    move => t.
    rewrite (Derive_ext (extension_C1 f m_infty m_infty)
      (fun y => f (real m_infty) + (y - real m_infty) * Derive f (real m_infty))).
    apply sym_eq ; apply is_derive_unique.
    eapply filterdiff_ext_lin.
    apply @filterdiff_plus_fct ; try by apply locally_filter.
    apply filterdiff_const.
    apply @filterdiff_scal_l_fct ; try by apply locally_filter.
    apply @filterdiff_minus_fct ; try by apply locally_filter.
    apply filterdiff_id.
    apply filterdiff_const.
    simpl => y.
    rewrite /minus /plus /opp /zero /scal /= /mult /=.
    ring.
  move => /= t0 ; rewrite /extension_C1.
  repeat case: Rbar_le_dec => // ; intros.
  by apply continuity_pt_const.
(* a = x *)
  case: a Hab Hf Hax => [a | | ] // Hab Hf Hax.
  apply Rbar_finite_eq in Hax ; rewrite -Hax => {x Hax}.
  case: (Rbar_le_lt_or_eq_dec _ _ Hab) => {Hab} Hab.
  (* a < b *)
  apply continuity_pt_ext_loc with (fun x : R =>
     match Rle_dec x a with
      | left _ => Derive f a
      | right _ =>  Derive f x
    end).
  case: (Rbar_lt_locally m_infty b a) => // d Hd.
  exists d => y Hy ; case: Rle_dec => Htb ; apply sym_eq, is_derive_unique.
  apply extension_C1_is_derive_a.
  now apply Rbar_lt_le.
  exact Htb.
  apply Hf.
  apply Rle_refl.
  now apply Rbar_lt_le.
  apply extension_C1_is_derive.
  by apply Rbar_lt_le, Rnot_le_lt.
  by apply Rbar_lt_le, Hd.
  apply Derive_correct, Hf.
  by apply Rbar_lt_le, Rnot_le_lt.
  by apply Rbar_lt_le, Hd.
  apply extension_cont.
  by apply continuity_pt_const.
  apply Hf.
  apply Rle_refl.
  now apply Rbar_lt_le.
  by [].
  (* a = b *)
  case: b Hf Hab => [b | | ] // Hf Hab.
  rewrite -Hab in Hf |- * => {b Hab}.
  apply continuity_pt_ext with (fun _ => Derive f a).
  move => t.
  rewrite (Derive_ext (extension_C1 f a a)
      (fun y => f (real a) + (y - real a) * Derive f (real a))).
  apply sym_eq ; apply is_derive_unique.
    eapply filterdiff_ext_lin.
    apply @filterdiff_plus_fct ; try by apply locally_filter.
    apply filterdiff_const.
    apply @filterdiff_scal_l_fct ; try by apply locally_filter.
    apply @filterdiff_minus_fct ; try by apply locally_filter.
    apply filterdiff_id.
    apply filterdiff_const.
    simpl => y.
    rewrite /minus /plus /opp /zero /scal /= /mult /=.
    ring.
  move => /= t0 ; rewrite /extension_C1.
  repeat case: Rbar_le_dec => // ; intros.
  rewrite (Rle_antisym t0 a) ; try easy.
  ring.
  by apply continuity_pt_const.
(* x < a *)
  case: a Hab Hf Hax => [a | | ] // Hab Hf Hax.
  apply continuity_pt_ext_loc with (fun _ => Derive f a).
  apply (locally_interval _ _ m_infty a) => // y Hay Hyb.
  apply sym_eq, is_derive_unique.
  apply extension_C1_is_derive_a => //.
  by apply Rlt_le.
  apply Hf => //.
  by right.
  by apply continuity_pt_const.
  case: b Hab Hf => [b | | ] Hab Hf // ; try by case: Hab.
  apply continuity_pt_ext with (fun _ => Derive f 0).
    move => t.
    rewrite (Derive_ext (extension_C1 f p_infty p_infty)
      (fun y => f (real p_infty) + (y - real p_infty) * Derive f (real p_infty))).
    apply sym_eq ; apply is_derive_unique.
    eapply filterdiff_ext_lin.
    apply @filterdiff_plus_fct ; try by apply locally_filter.
    apply filterdiff_const.
    apply @filterdiff_scal_l_fct ; try apply locally_filter.
    apply @filterdiff_minus_fct ; try apply locally_filter.
    apply filterdiff_id.
    apply filterdiff_const.
    simpl => y.
    rewrite /minus /plus /opp /zero /scal /= /mult /=.
    ring.
  move => /= t0 ; rewrite /extension_C1.
  repeat case: Rbar_le_dec => // ; intros.
  by apply continuity_pt_const.
Qed.

(** Alternate definition of differentiability *)

(*Definition derivable_pt_lim_aux (f : R -> R) (x l : R) :=
  forall eps : posreal,
  locally x (fun y => Rabs (f y - f x - l * (y-x)) <= eps * Rabs (y-x)).

Lemma equiv_deriv_pt_lim_0 : forall f x l,
  derivable_pt_lim f x l -> derivable_pt_lim_aux f x l.
Proof.
  intros f x l.
  case/filterderive_Reals => /= HF H eps.
  destruct (H eps) as [d Hd].
  exists d.
Qed.

Lemma equiv_deriv_pt_lim_1 : forall f x l,
  derivable_pt_lim_aux f x l -> derivable_pt_lim f x l.
Proof.
  intros f x l Df.
  intros eps Heps.
  assert (He : 0 < eps/2).
    apply Rdiv_lt_0_compat.
    apply Heps.
    apply Rlt_R0_R2.
    set (eps2 := mkposreal _ He).
  elim (Df eps2) ; clear Df ; intros delta Df.
  exists delta ; intros.
  assert (x+h+ -x = h).
    ring.
  assert (((f (x + h) - f x) / h - l) = (f(x+h) - f x - l * ((x+h)-x))/((x+h)-x)).
    field.
    rewrite /Rminus H1 ;
    apply H.
    rewrite H2 ; clear H2.
  apply (Rle_lt_trans _ eps2).
  rewrite Rabs_div.
  apply (Rle_div_l _ _ (Rabs (x + h - x))).
  apply Rabs_pos_lt.
  rewrite /Rminus H1 ;
    apply H.
  apply (Df (x+h)).
  simpl.
  rewrite H1 ;
    apply H0.
    rewrite /Rminus H1 ; apply H.
  rewrite (double_var eps).
  rewrite <- (Rplus_0_r eps2).
  unfold eps2 ; simpl.
  apply Rplus_lt_compat_l.
  apply He.
Qed. *)

(** * Iterated differential *)

(** ** Definition *)

Fixpoint Derive_n (f : R -> R) (n : nat) x :=
  match n with
    | O => f x
    | S n => Derive (Derive_n f n) x
  end.

Definition ex_derive_n f n x :=
  match n with
  | O => True
  | S n => ex_derive (Derive_n f n) x
  end.

Definition is_derive_n f n x l :=
  match n with
  | O => f x = l
  | S n => is_derive (Derive_n f n) x l
  end.

Lemma is_derive_n_unique f n x l :
  is_derive_n f n x l -> Derive_n f n x = l.
Proof.
  case n.
  easy.
  simpl; intros n0 H.
  now apply is_derive_unique.
Qed.

Lemma Derive_n_correct f n x :
  ex_derive_n f n x -> is_derive_n f n x (Derive_n f n x).
Proof.
  case: n => /= [ | n] Hf.
  by [].
  by apply Derive_correct.
Qed.

(** Extensionality *)

Lemma Derive_n_ext_loc :
  forall f g n x,
  locally x (fun t => f t = g t) ->
  Derive_n f n x = Derive_n g n x.
Proof.
intros f g n x Heq.
pattern x ; apply locally_singleton.
induction n.
exact Heq.
apply locally_locally in IHn.
apply filter_imp with (2 := IHn) => {IHn}.
intros t H.
now apply Derive_ext_loc.
Qed.

Lemma ex_derive_n_ext_loc :
  forall f g n x,
  locally x (fun t => f t = g t) ->
  ex_derive_n f n x -> ex_derive_n g n x.
Proof.
intros f g n x Heq.
case: n => /= [ | n].
by [].
apply ex_derive_ext_loc.
apply locally_locally in Heq.
apply filter_imp with (2 := Heq) => {Heq}.
by apply Derive_n_ext_loc.
Qed.

Lemma is_derive_n_ext_loc :
  forall f g n x l,
  locally x (fun t => f t = g t) ->
  is_derive_n f n x l -> is_derive_n g n x l.
Proof.
  intros f g n x l Heq.
  case: n => /= [ | n].
  move => <- ; apply sym_eq.
  pattern x ; now apply locally_singleton.
  apply is_derive_ext_loc.
  apply locally_locally in Heq.
  apply filter_imp with (2 := Heq) => {Heq}.
  by apply Derive_n_ext_loc.
Qed.

Lemma Derive_n_ext :
  forall f g n x,
  (forall t, f t = g t) ->
  Derive_n f n x = Derive_n g n x.
Proof.
intros f g n x Heq.
apply Derive_n_ext_loc.
by apply filter_forall.
Qed.

Lemma ex_derive_n_ext :
  forall f g n x,
  (forall t, f t = g t) ->
  ex_derive_n f n x -> ex_derive_n g n x.
Proof.
intros f g n x Heq.
apply ex_derive_n_ext_loc.
by apply filter_forall.
Qed.

Lemma is_derive_n_ext :
  forall f g n x l,
  (forall t, f t = g t) ->
  is_derive_n f n x l -> is_derive_n g n x l.
Proof.
intros f g n x l Heq.
apply is_derive_n_ext_loc.
by apply filter_forall.
Qed.

Lemma Derive_n_comp: forall f n m x,
  Derive_n (Derive_n f m) n x = Derive_n f (n+m) x.
Proof.
intros f n m.
induction n.
now simpl.
simpl.
intros x.
now apply Derive_ext.
Qed.

Lemma is_derive_Sn (f : R -> R) (n : nat) (x l : R) :
  locally x (ex_derive f) ->
  (is_derive_n f (S n) x l <-> is_derive_n (Derive f) n x l).
Proof.
  move => Hf.
  case: n => /= [ | n].
  split => H.
  by apply is_derive_unique.
  rewrite -H ; apply Derive_correct.
  now apply locally_singleton.
  split => Hf'.
  - apply is_derive_ext with (2 := Hf').
    move => y ; rewrite (Derive_n_comp _ n 1%nat).
    by (replace (n + 1)%nat with (S n) by ring).
  - apply is_derive_ext with (2 := Hf').
    move => y ; rewrite (Derive_n_comp _ n 1%nat).
    by (replace (n + 1)%nat with (S n) by ring).
Qed.

(** ** Operations *)
(** *** Additive operators *)
(** Opposite *)

Lemma Derive_n_opp (f : R -> R) (n : nat) (x : R) :
  Derive_n (fun x => - f x) n x = - Derive_n f n x.
Proof.
  elim: n x => [ | n IH] x /=.
  by [].
  rewrite -Derive_opp_fct.
  by apply Derive_ext.
Qed.

Lemma ex_derive_n_opp (f : R -> R) (n : nat) (x : R) :
  ex_derive_n f n x -> ex_derive_n (fun x => -f x) n x.
Proof.
  case: n x => [ | n] /= x Hf.
  by [].
  apply ex_derive_opp_fct in Hf.
  apply: ex_derive_ext Hf.
  move => y ; by rewrite Derive_n_opp.
Qed.

Lemma is_derive_n_opp (f : R -> R) (n : nat) (x l : R) :
  is_derive_n f n x l -> is_derive_n (fun x => -f x) n x (- l).
Proof.
  case: n x => [ | n] /= x Hf.
  by rewrite Hf.
  apply is_derive_opp_fct in Hf.
  apply: is_derive_ext Hf.
  move => y ; by rewrite Derive_n_opp.
Qed.

(** Addition of functions *)

Lemma Derive_n_plus (f g : R -> R) (n : nat) (x : R) :
  locally x (fun y => forall k, (k <= n)%nat -> ex_derive_n f k y) ->
  locally x (fun y => forall k, (k <= n)%nat -> ex_derive_n g k y) ->
  Derive_n (fun x => f x + g x) n x = Derive_n f n x + Derive_n g n x.
Proof.
  elim: n x => /= [ | n IH] x [rf Hf] [rg Hg].
  by [].
  rewrite -Derive_plus.
  apply Derive_ext_loc.
  set r := (mkposreal _ (Rmin_stable_in_posreal rf rg)) ;
  exists r => y Hy.
  rewrite /ball /= /AbsRing_ball /= in Hy.
  apply Rabs_lt_between' in Hy.
  case: Hy ; move/Rlt_Rminus => Hy1 ; move/Rlt_Rminus => Hy2.
  set r0 := mkposreal _ (Rmin_pos _ _ Hy1 Hy2).
  apply IH ;
  exists r0 => z Hz k Hk.
  apply Hf.
  rewrite /ball /= /AbsRing_ball /= in Hz.
  apply Rabs_lt_between' in Hz.
  rewrite /Rminus -Rmax_opp_Rmin Rplus_max_distr_l (Rplus_min_distr_l y) in Hz.
  case: Hz ; move => Hz1 Hz2.
  apply Rle_lt_trans with (1 := Rmax_l _ _) in Hz1 ; ring_simplify in Hz1.
  apply Rlt_le_trans with (2 := Rmin_r _ _) in Hz2 ; ring_simplify (y + (x + Rmin rf rg + - y)) in Hz2.
  have Hz := (conj Hz1 Hz2) => {Hz1 Hz2}.
  apply Rabs_lt_between' in Hz.
  apply Rlt_le_trans with (1 := Hz) => /= ; by apply Rmin_l.
  by apply le_trans with (1 := Hk), le_n_Sn.
  apply Hg.
  rewrite /ball /= /AbsRing_ball /= in Hz.
  apply Rabs_lt_between' in Hz.
  rewrite /Rminus -Rmax_opp_Rmin Rplus_max_distr_l (Rplus_min_distr_l y) in Hz.
  case: Hz ; move => Hz1 Hz2.
  apply Rle_lt_trans with (1 := Rmax_l _ _) in Hz1 ; ring_simplify in Hz1.
  apply Rlt_le_trans with (2 := Rmin_r _ _) in Hz2 ; ring_simplify (y + (x + Rmin rf rg + - y)) in Hz2.
  have Hz := (conj Hz1 Hz2) => {Hz1 Hz2}.
  apply Rabs_lt_between' in Hz.
  apply Rlt_le_trans with (1 := Hz) => /= ; by apply Rmin_r.
  by apply le_trans with (1 := Hk), le_n_Sn.
  apply Hf with (k := (S n)).
  by apply ball_center. 
  by apply le_refl.
  apply Hg with (k := S n).
  by apply ball_center.
  by apply le_refl.
Qed.

Lemma ex_derive_n_plus (f g : R -> R) (n : nat) (x : R) :
  locally x (fun y => forall k, (k <= n)%nat -> ex_derive_n f k y) ->
  locally x (fun y => forall k, (k <= n)%nat -> ex_derive_n g k y) ->
  ex_derive_n (fun x => f x + g x) n x.
Proof.
  case: n x => /= [ | n] x Hf Hg.
  by [].
  apply ex_derive_ext_loc with (fun y => Derive_n f n y + Derive_n g n y).
  apply locally_locally in Hf.
  apply locally_locally in Hg.
  generalize (filter_and _ _ Hf Hg).
  apply filter_imp => {Hf Hg} y [Hf Hg].
  apply sym_eq, Derive_n_plus.
  apply filter_imp with (2 := Hf) ; by intuition.
  apply filter_imp with (2 := Hg) ; by intuition.
  apply: ex_derive_plus.
  apply locally_singleton ; apply filter_imp with (2 := Hf) => {Hf} y Hy ;
  by apply (Hy (S n)).
  apply locally_singleton ; apply filter_imp with (2 := Hg) => {Hg} y Hy ;
  by apply (Hy (S n)).
Qed.

Lemma is_derive_n_plus (f g : R -> R) (n : nat) (x lf lg : R) :
  locally x (fun y => forall k, (k <= n)%nat -> ex_derive_n f k y) ->
  locally x (fun y => forall k, (k <= n)%nat -> ex_derive_n g k y) ->
  is_derive_n f n x lf -> is_derive_n g n x lg ->
  is_derive_n (fun x => f x + g x) n x (lf + lg).
Proof.
  case: n x lf lg => /= [ | n] x lf lg Hfn Hgn Hf Hg.
  by rewrite Hf Hg.
  apply is_derive_ext_loc with (fun y => Derive_n f n y + Derive_n g n y).
  apply locally_locally in Hfn.
  apply locally_locally in Hgn.
  generalize (filter_and _ _ Hfn Hgn).
  apply filter_imp => {Hfn Hgn} y [Hfn Hgn].
  apply sym_eq, Derive_n_plus.
  apply filter_imp with (2 := Hfn) ; by intuition.
  apply filter_imp with (2 := Hgn) ; by intuition.
  apply is_derive_Reals, derivable_pt_lim_plus ;
    now apply is_derive_Reals.
Qed.

(** Subtraction of functions *)

Lemma Derive_n_minus (f g : R -> R) (n : nat) (x : R) :
  locally x (fun y => forall k, (k <= n)%nat -> ex_derive_n f k y) ->
  locally x (fun y => forall k, (k <= n)%nat -> ex_derive_n g k y) ->
  Derive_n (fun x => f x - g x) n x = Derive_n f n x - Derive_n g n x.
Proof.
  move => Hf Hg.
  rewrite Derive_n_plus.
  by rewrite Derive_n_opp.
  by [].
  move: Hg ; apply filter_imp => y Hg k Hk.
  apply ex_derive_n_opp ; by apply Hg.
Qed.
Lemma ex_derive_n_minus (f g : R -> R) (n : nat) (x : R) :
  locally x (fun y => forall k, (k <= n)%nat -> ex_derive_n f k y) ->
  locally x (fun y => forall k, (k <= n)%nat -> ex_derive_n g k y) ->
  ex_derive_n (fun x => f x - g x) n x.
Proof.
  move => Hf Hg.
  apply ex_derive_n_plus.
  by [].
  move: Hg ; apply filter_imp => y Hg k Hk.
  apply ex_derive_n_opp ; by apply Hg.
Qed.
Lemma is_derive_n_minus (f g : R -> R) (n : nat) (x lf lg : R) :
  locally x (fun y => forall k, (k <= n)%nat -> ex_derive_n f k y) ->
  locally x (fun y => forall k, (k <= n)%nat -> ex_derive_n g k y) ->
  is_derive_n f n x lf -> is_derive_n g n x lg ->
  is_derive_n (fun x => f x - g x) n x (lf - lg).
Proof.
  move => Hf Hg Df Dg.
  apply is_derive_n_plus.
  by [].
  move: Hg ; apply filter_imp => y Hg k Hk.
  apply ex_derive_n_opp ; by apply Hg.
  by [].
  by apply is_derive_n_opp.
Qed.

(** *** Multiplicative operators *)

(** Scalar multiplication *)

Lemma Derive_n_scal_l (f : R -> R) (n : nat) (a x : R) :
  Derive_n (fun y => a * f y) n x = a * Derive_n f n x.
Proof.
  elim: n x => /= [ | n IH] x.
  by [].
  rewrite -Derive_scal_fct.
  by apply Derive_ext.
Qed.

Lemma ex_derive_n_scal_l (f : R -> R) (n : nat) (a x : R) :
  ex_derive_n f n x -> ex_derive_n (fun y => a * f y) n x.
Proof.
  case: n x => /= [ | n] x Hf.
  by [].
  apply ex_derive_ext with (fun y => a * Derive_n f n y).
  move => t ; by rewrite Derive_n_scal_l.
  now apply ex_derive_scal_fct.
Qed.

Lemma is_derive_n_scal_l (f : R -> R) (n : nat) (a x l : R) :
  is_derive_n f n x l -> is_derive_n (fun y => a * f y) n x (a * l).
Proof.
  case: n x => /= [ | n] x Hf.
  by rewrite Hf.
  eapply filterdiff_ext_lin.
  apply filterdiff_ext with (fun y => a * Derive_n f n y).
  move => t ; by rewrite Derive_n_scal_l.
  apply @filterdiff_scal_r_fct ; try by apply locally_filter.
  by apply Rmult_comm.
  apply Hf.
  move => /= y.
  rewrite /scal /= /mult /=.
  ring.
Qed.

Lemma Derive_n_scal_r (f : R -> R) (n : nat) (a x : R) :
  Derive_n (fun y => f y * a) n x = Derive_n f n x * a.
Proof.
  rewrite Rmult_comm -Derive_n_scal_l.
  apply Derive_n_ext => y ; ring.
Qed.
Lemma ex_derive_n_scal_r (f : R -> R) (n : nat) (a x : R) :
  ex_derive_n f n x -> ex_derive_n (fun y => f y * a) n x.
Proof.
  move/(ex_derive_n_scal_l _ _ a).
  apply ex_derive_n_ext => y ; ring.
Qed.
Lemma is_derive_n_scal_r (f : R -> R) (n : nat) (a x l : R) :
  is_derive_n f n x l -> is_derive_n (fun y => f y * a) n x (l * a).
Proof.
  move/(is_derive_n_scal_l _ _ a).
  rewrite Rmult_comm.
  apply is_derive_n_ext => y ; ring.
Qed.

(** *** Composition *)

(** Composition with linear functions *)

Lemma Derive_n_comp_scal (f : R -> R) (a : R) (n : nat) (x : R) :
  locally (a * x) (fun x => forall k, (k <= n)%nat -> ex_derive_n f k x) ->
  Derive_n (fun y => f (a * y)) n x  = (a ^ n * Derive_n f n (a * x)).
Proof.
  case: (Req_dec a 0) => [ -> _ | Ha] /=.
  rewrite Rmult_0_l.
  elim: n x => [ | n IH] x /= ; rewrite ?Rmult_0_l.
  ring.
  rewrite (Derive_ext _ _ _ IH).
  by apply Derive_const.

  move => Hf.
  apply (locally_singleton _ (fun x => Derive_n (fun y : R => f (a * y)) n x = a ^ n * Derive_n f n (a * x))).
  elim: n Hf => [ | n IH] Hf.
  apply filter_forall => /= y ; ring.

  case: IH => [ | r IH].
  case: Hf => r0 Hf.
  exists r0 => y Hy k Hk ; by intuition.
  case: Hf => r0 Hf.
  have Hr1 : 0 < Rmin (r0 / (Rabs a)) r.
    apply Rmin_case.
    apply Rdiv_lt_0_compat.
    by apply r0.
    by apply Rabs_pos_lt.
    by apply r.
  set r1 := mkposreal _ Hr1.
  exists r1 => y Hy /=.
  rewrite (Derive_ext_loc _ (fun y => a ^ n * Derive_n f n (a * y))).
  rewrite Derive_scal_fct.
  rewrite (Rmult_comm a (a^n)) Rmult_assoc.
  apply f_equal.
  rewrite Derive_comp.
  rewrite (Derive_ext (Rmult a) (fun x => a * x)) => //.
  rewrite Derive_scal_fct Derive_id ; ring.
  apply Hf with (k := S n).
  rewrite /ball /= /AbsRing_ball /= /abs /minus /plus /opp /=.
  rewrite -/(Rminus _ _) -Rmult_minus_distr_l Rabs_mult.
  apply Rlt_le_trans with (Rabs a * r1).
  apply Rmult_lt_compat_l.
  by apply Rabs_pos_lt.
  by apply Hy.
  rewrite Rmult_comm ; apply Rle_div_r.
  by apply Rabs_pos_lt.
  rewrite /r1 ; by apply Rmin_l.
  by apply lt_n_Sn.
  apply ex_derive_scal_fct.
  by apply ex_derive_id.
  rewrite /ball /= /AbsRing_ball /= in Hy.
  apply Rabs_lt_between' in Hy.
  case: Hy => Hy1 Hy2.
  apply Rlt_Rminus in Hy1.
  apply Rlt_Rminus in Hy2.
  have Hy : 0 < Rmin (y - (x - r1)) (x + r1 - y).
  by apply Rmin_case.
  exists (mkposreal (Rmin (y - (x - r1)) (x + r1 - y)) Hy).
  set r2 := Rmin (y - (x - r1)) (x + r1 - y).
  move => t Ht.
  apply IH.
  apply Rabs_lt_between'.
  rewrite /ball /= /AbsRing_ball /= in Ht.
  apply Rabs_lt_between' in Ht.
  simpl in Ht.
  split.
  apply Rle_lt_trans with (2 := proj1 Ht).
  rewrite /r2 ; apply Rle_trans with (y-(y-(x-r1))).
  ring_simplify ; apply Rplus_le_compat_l, Ropp_le_contravar.
  rewrite /r1 ; apply Rmin_r.
  apply Rplus_le_compat_l, Ropp_le_contravar, Rmin_l.
  apply Rlt_le_trans with (1 := proj2 Ht).
  rewrite /r2 ; apply Rle_trans with (y+((x+r1)-y)).
  apply Rplus_le_compat_l, Rmin_r.
  ring_simplify ; apply Rplus_le_compat_l.
  rewrite /r1 ; apply Rmin_r.
Qed.

Lemma ex_derive_n_comp_scal (f : R -> R) (a : R) (n : nat) (x : R) :
  locally (a * x) (fun x => forall k, (k <= n)%nat -> ex_derive_n f k x)
  -> ex_derive_n (fun y => f (a * y)) n x.
Proof.
  case: n f x => /= [ | n] f x Hf.
  by [].

  case: (Req_dec a 0) => Ha.
  rewrite Ha => {a Ha Hf}.
  apply ex_derive_ext with (fun _ => Derive_n (fun y : R => f (0 * y)) n 0).
  elim: n => /= [ | n IH] t.
  by rewrite ?Rmult_0_l.
  rewrite -?(Derive_ext _ _ _ IH).
  by rewrite ?Derive_const.
  by apply ex_derive_const.
  apply ex_derive_ext_loc with (fun x => a^n * Derive_n f n (a * x)).
    case: Hf => r Hf.
    have Hr0 : 0 < r / Rabs a.
      apply Rdiv_lt_0_compat.
      by apply r.
      by apply Rabs_pos_lt.
    exists (mkposreal _ Hr0) => /= y Hy.
    apply eq_sym, Derive_n_comp_scal.
    have : Rabs (a*y - a*x) < r.
      rewrite -Rmult_minus_distr_l Rabs_mult.
      replace (pos r) with (Rabs a * (r / Rabs a))
        by (field ; by apply Rgt_not_eq, Rabs_pos_lt).
      apply Rmult_lt_compat_l.
      by apply Rabs_pos_lt.
      by apply Hy.
      move => {Hy} Hy.
    apply Rabs_lt_between' in Hy ; case: Hy => Hy1 Hy2.
    apply Rlt_Rminus in Hy1.
    apply Rlt_Rminus in Hy2.
    exists (mkposreal _ (Rmin_pos _ _ Hy1 Hy2)) => /= z Hz k Hk.
    rewrite /ball /= /AbsRing_ball /= in Hz.
    apply Rabs_lt_between' in Hz ; case: Hz => Hz1 Hz2.
    rewrite /Rminus -Rmax_opp_Rmin in Hz1.
    rewrite Rplus_min_distr_l in Hz2.
    apply Rlt_le_trans with (2 := Rmin_r _ _) in Hz2.
    ring_simplify in Hz2.
    rewrite Rplus_max_distr_l in Hz1.
    apply Rle_lt_trans with (1 := Rmax_l _ _) in Hz1.
    ring_simplify in Hz1.
    apply Hf.
    apply Rabs_lt_between' ; by split.
    by intuition.
  apply ex_derive_scal_fct.
  apply ex_derive_comp.
  apply (locally_singleton _ _) in Hf.
  by apply Hf with (k := S n).

  apply (ex_derive_scal_fct id a x (ex_derive_id _)).
Qed.

Lemma is_derive_n_comp_scal (f : R -> R) (a : R) (n : nat) (x l : R) :
  locally (a * x) (fun x => forall k, (k <= n)%nat -> ex_derive_n f k x)
  -> is_derive_n f n (a * x) l
  -> is_derive_n (fun y => f (a * y)) n x (a ^ n * l).
Proof.
  case: n => /= [ | n] Hfn Hf.
  by rewrite Rmult_1_l.
  apply is_derive_unique in Hf.
  rewrite -Hf.
  rewrite -(Derive_n_comp_scal f a (S n) x) => //.
  apply Derive_correct.
  by apply (ex_derive_n_comp_scal f a (S n) x).
Qed.

Lemma Derive_n_comp_opp (f : R -> R) (n : nat) (x : R) :
  locally (- x) (fun y => (forall k, (k <= n)%nat -> ex_derive_n f k y)) ->
  Derive_n (fun y => f (- y)) n x  = ((-1) ^ n * Derive_n f n (-x)).
Proof.
  move => Hf.
  rewrite -(Derive_n_ext (fun y : R => f (-1 * y))).
  rewrite (Derive_n_comp_scal f (-1) n x).
  by replace (-1*x) with (-x) by ring.
  by replace (-1*x) with (-x) by ring.
  move => t ; by replace (-1*t) with (-t) by ring.
Qed.
Lemma ex_derive_n_comp_opp (f : R -> R) (n : nat) (x : R) :
  locally (- x) (fun y => (forall k, (k <= n)%nat -> ex_derive_n f k y)) ->
  ex_derive_n (fun y => f (- y)) n x.
Proof.
  move => Hf.
  apply (ex_derive_n_ext (fun y : R => f (-1 * y))).
  move => t ; by ring_simplify (-1*t).
  apply (ex_derive_n_comp_scal f (-1) n x).
  by replace (-1*x) with (-x) by ring.
Qed.
Lemma is_derive_n_comp_opp (f : R -> R) (n : nat) (x l : R) :
  locally (- x) (fun y => (forall k, (k <= n)%nat -> ex_derive_n f k y)) ->
  is_derive_n f n (-x) l ->
  is_derive_n (fun y => f (- y)) n x ((-1)^n * l).
Proof.
  move => Hfn Hf.
  apply (is_derive_n_ext (fun y : R => f (-1 * y))).
  move => t ; by ring_simplify (-1*t).
  apply (is_derive_n_comp_scal f (-1) n x).
  by replace (-1*x) with (-x) by ring.
  by replace (-1*x) with (-x) by ring.
Qed.

Lemma Derive_n_comp_trans (f : R -> R) (n : nat) (x b : R) :
  Derive_n (fun y => f (y + b)) n x  = Derive_n f n (x + b).
Proof.
  elim: n x => [ | n IH] x /=.
  by [].
  rewrite (Derive_ext _ _ _ IH) => {IH}.
  generalize (Derive_n f n) => {f} f.
  apply (f_equal real).
  apply Lim_ext => y.
  replace (x + b + y) with (x + y + b) by ring.
  by [].
Qed.

Lemma ex_derive_n_comp_trans (f : R -> R) (n : nat) (x b : R) :
  ex_derive_n f n (x + b) ->
  ex_derive_n (fun y => f (y + b)) n x.
Proof.
  case: n => [ | n] /= Df.
  by [].
  apply ex_derive_ext with (fun x => Derive_n f n (x + b)).
  simpl => t.
  apply sym_eq, Derive_n_comp_trans.
  move: (Derive_n f n) Df => {f} f Df.
  apply ex_derive_comp.
  apply Df.
  apply: ex_derive_plus.
  apply ex_derive_id.
  apply ex_derive_const.
Qed.

Lemma is_derive_n_comp_trans (f : R -> R) (n : nat) (x b l : R) :
  is_derive_n f n (x + b) l ->
  is_derive_n (fun y => f (y + b)) n x l.
Proof.
  case: n => [ | n] /= Df.
  by [].
  apply is_derive_ext with (fun x => Derive_n f n (x + b)).
  simpl => t.
  apply sym_eq, Derive_n_comp_trans.
  move: (Derive_n f n) Df => {f} f Df.
  eapply filterdiff_ext_lin.
  apply @filterdiff_compose'.
  apply @filterdiff_plus_fct ; try by apply locally_filter.
  by apply filterdiff_id.
  by apply filterdiff_const.
  by apply Df.
  simpl => y.
  by rewrite plus_zero_r.
Qed.

(** * Taylor-Lagrange formula *)

Theorem Taylor_Lagrange :
  forall f n x y, x < y ->
  ( forall t, x <= t <= y -> forall k, (k <= S n)%nat -> ex_derive_n f k t ) ->
  exists zeta, x < zeta < y /\
    f y =  sum_f_R0 (fun m => (y-x) ^ m / INR (fact m) * Derive_n f m x )  n
        + (y-x) ^ (S n) / INR (fact (S n)) * Derive_n f (S n) zeta.
Proof.
intros f n x y Hxy Df.
pose (c:= (f y - sum_f_R0 (fun m => (y-x) ^ m / INR (fact m) * Derive_n f m x )  n)
                / (y-x) ^ (S n)).
pose (g t := f y - sum_f_R0 (fun m => (y-t) ^ m / INR (fact m) * Derive_n f m t )  n
               - c * (y-t) ^ (S n)).
assert (Dg : forall t, x <= t <= y -> is_derive g t
  (- (y-t) ^ n / INR (fact n) * Derive_n f (S n) t + c * INR (S n) * (y-t) ^ n)).
intros t Ht.
unfold g.
assert (Dp: forall n, derivable_pt_lim (fun x0 : R => (y - x0) ^ S n) t (INR (S n) * (y - t) ^ n * (0 - 1))).
intros m.
apply (derivable_pt_lim_comp (fun t => y - t) (fun t => t ^ (S m))).
apply derivable_pt_lim_minus.
apply derivable_pt_lim_const.
apply derivable_pt_lim_id.
apply derivable_pt_lim_pow.
(* *)
apply is_derive_Reals, derivable_pt_lim_plus.
(* . *)
clear c g.
rename n into N.
generalize (le_refl N).
generalize N at -2.
intros n Hn.
apply is_derive_Reals.
move: Hn.
induction n.
(* .. *)
intros _.
simpl.
eapply filterdiff_ext_lin.
apply @filterdiff_minus_fct ; try by apply locally_filter.
apply filterdiff_const.
apply @filterdiff_scal_r_fct with (f := fun u => f u).
by apply locally_filter.
by apply Rmult_comm.
apply Derive_correct.
apply (Df t Ht 1%nat).
apply le_n_S.
apply le_0_n.
simpl => z.
rewrite /minus /plus /opp /zero /scal /= /mult /=.
field.
(* .. *)
intros Hn.
apply filterdiff_ext with (fun x0 : R =>
   (f y -
   (sum_f_R0 (fun m : nat => (y - x0) ^ m / INR (fact m) * Derive_n f m x0) n)) -
    (y - x0) ^ (S n) / INR (fact (S n)) *
     Derive_n f (S n) x0).
simpl.
intros; ring.
eapply filterdiff_ext_lin.
apply @filterdiff_plus_fct ; try by apply locally_filter.
apply IHn.
now apply lt_le_weak.
apply @filterdiff_opp_fct ; try by apply locally_filter.
generalize (filterdiff_mult_fct (fun x0 => ((y - x0) ^ S n / INR (fact (S n))))
  (fun x0 => Derive_n f (S n) x0)) => /= H.
apply H ; clear H.
by apply Rmult_comm.
apply @filterdiff_scal_l_fct ; try by apply locally_filter.
generalize (filterdiff_compose' (fun u => y - u) (fun x => pow x (S n))) => /= H ;
apply H ; clear H.
apply @filterdiff_minus_fct ; try apply locally_filter.
apply filterdiff_const.
apply filterdiff_id.
apply is_derive_Reals.
apply (derivable_pt_lim_pow _ (S n)).
apply Derive_correct.
apply (Df t Ht (S (S n))).
now apply le_n_S.
move => z.
change (fact (S n)) with ((S n)*fact n)%nat.
rewrite mult_INR.
set v := INR (S n).
rewrite /minus /plus /opp /zero /scal /= /mult /=.
field.
split.
apply INR_fact_neq_0.
destruct n.
apply Rgt_not_eq, Rlt_0_1.
apply Rgt_not_eq, INRp1_pos.
(* . *)
apply is_derive_Reals.
eapply filterdiff_ext_lin.
apply filterdiff_ext with (fun x0 : R => -c * (y - x0) ^ S n).
simpl => z ; ring.
apply @filterdiff_scal_r_fct ; try by apply locally_filter.
by apply Rmult_comm.
apply is_derive_Reals, Dp.
set v := INR (S n).
simpl => z.
rewrite /scal /= /mult /=.
ring.
(* *)
assert (Dg' : forall t : R, x <= t <= y -> derivable_pt g t).
intros t Ht.
exists (Derive g t).
apply is_derive_Reals.
apply Derive_correct.
eexists.
apply (Dg t Ht).
assert (pr : forall t : R, x < t < y -> derivable_pt g t).
intros t Ht.
apply Dg'.
split ; now apply Rlt_le.
(* *)
assert (Zxy: (y - x) ^ (S n) <> 0).
apply pow_nonzero.
apply Rgt_not_eq.
apply Rplus_gt_reg_l with x.
now ring_simplify.
(* *)
destruct (Rolle g x y pr) as (zeta, (Hzeta1,Hzeta2)).
intros t Ht.
apply derivable_continuous_pt.
now apply Dg'.
exact Hxy.
apply trans_eq with 0.
unfold g, c.
now field.
unfold g.
destruct n.
simpl; field.
rewrite decomp_sum.
rewrite sum_eq_R0.
simpl; field.
intros; simpl; field.
exact (INR_fact_neq_0 (S n0)).
apply lt_0_Sn.
exists zeta.
apply (conj Hzeta1).
rewrite Rmult_assoc.
replace (/ INR (fact (S n)) * Derive_n f (S n) zeta) with c.
unfold c.
now field.
apply Rmult_eq_reg_r with (INR (S n) * (y - zeta) ^ n).
apply Rplus_eq_reg_l with ((- (y - zeta) ^ n / INR (fact n) * Derive_n f (S n) zeta)).
change (fact (S n)) with (S n * fact n)%nat.
rewrite mult_INR.
apply trans_eq with R0.
rewrite -Rmult_assoc.
assert (H: x <= zeta <= y) by (split ; apply Rlt_le ; apply Hzeta1).
rewrite -(is_derive_unique _ _ _ (Dg _ H)).
destruct (pr zeta Hzeta1) as (x0,Hd).
simpl in Hzeta2.
rewrite Hzeta2 in Hd.
now apply is_derive_unique, is_derive_Reals.
field.
split.
apply INR_fact_neq_0.
now apply not_0_INR.
apply Rmult_integral_contrapositive_currified.
now apply not_0_INR.
apply pow_nonzero.
apply Rgt_not_eq.
apply Rplus_gt_reg_l with zeta.
ring_simplify.
apply Hzeta1.
Qed.
