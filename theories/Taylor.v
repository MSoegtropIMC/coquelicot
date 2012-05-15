Require Import Reals Arithmetique.
Require Import ssreflect.
Require Import Lim_seq Lim_fct Sup_seq Rbar_seq Deriv_fct.




Definition partial_derive (m k : nat) (f : R -> R -> R) : R -> R -> R :=
  fun x y => Deriv_n (fun t => Deriv_n (fun z => f t z) k y) m x.

Definition differential (p : nat) (f : R -> R -> R) (x y dx dy : R) : R :=
  sum_f_R0 
    (fun m =>
      C p m *
      partial_derive m (p - m)%nat f x y *
      dx ^ m * dy ^ (p - m)%nat)
    p.

Definition DL_pol (n : nat) (f : R -> R -> R) (x y dx dy : R) : R :=
  sum_f_R0
    (fun p =>
      differential p f x y dx dy / INR (fact p))
    n.


Definition continuity2_pt (f : R -> R -> R) (x y : R) :=
  forall eps : posreal, exists delta : posreal, forall (x' y' : R),
    Rabs (x'-x) < delta -> Rabs (y'-y) < delta -> Rabs (f x' y' - f x y) < eps.
Definition continuity2 (f : R -> R -> R) :=
  forall (x y : R), continuity2_pt f x y.

Definition ex_diff_n f n x y :=
    (exists eps : posreal, forall m k, (m+k < n)%nat 
          -> forall u v, Rabs (u-x) < eps -> Rabs (v-y) < eps 
             ->  ex_deriv (fun z => partial_derive m k f z v) u /\
                 ex_deriv (fun z => partial_derive m k f u z) v )
    /\
    (forall m k, (m+k <= n)%nat 
          ->  continuity2_pt (fun u v => partial_derive m k f u v) x y).


Definition DL_regular_n f m x y :=
    exists D, exists delta: posreal, forall u v,
    Rabs (u-x) < delta -> Rabs (v-y) < delta ->
       Rabs (f u v - DL_pol m f x y (u-x) (v-y)) <= D * (Rmax (Rabs (u-x)) (Rabs (v-y))) ^ (S m).

Lemma MVT_cor4:
  forall (f : R -> R) a eps,
  (forall c, Rabs (c - a) <= eps -> ex_deriv f c) ->
  forall b, (Rabs (b - a) <= eps) ->
  exists c, f b - f a = Deriv f c * (b - a) /\ (Rabs (c - a) <= Rabs (b - a)).
Proof.
intros f a eps Hf' b.
unfold Rabs at 1 3.
case Rcase_abs; intros H1 H2.
destruct (MVT_cor2 f (Deriv f) b a).
apply Rplus_lt_reg_r with (-a).
ring_simplify.
now rewrite Rplus_comm.
intros c Hc.
apply Deriv_prop.
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
destruct (MVT_cor2 f (Deriv f) a b).
apply Rplus_lt_reg_r with (-a).
ring_simplify.
now rewrite Rplus_comm.
intros c Hc.
apply Deriv_prop.
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
  (forall t, Rabs (t - x) <= Rabs (y - x) -> ex_deriv h t /\ (Rabs (Deriv h t) <= D)) ->
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

Lemma ex_deriv_eta: forall f g,
   (forall y, f y = g y) -> forall x, ex_deriv f x -> ex_deriv g x.
intros f g Hfg x (l,Hf).
exists l.
intros t Ht.
destruct (Hf t Ht).
exists x0; intros h Hh1 Hh2.
rewrite <- 2!Hfg.
now apply H.
Qed.

Lemma Deriv_eta: forall f g, 
   (forall y, f y = g y) -> forall x, Deriv f x = Deriv g x.
Proof.
intros f g Hfg x.
unfold Deriv, Lim, Lim_seq.
apply f_equal.
rewrite 2!LimSup_seq_correct.
apply Rbar_limsup_eq.
intros n; now rewrite 2!Hfg.
Qed.

Lemma Deriv_n_eta: forall f g, 
   (forall y, f y = g y) -> forall n x, Deriv_n f n x = Deriv_n g n x.
Proof.
intros f g Hfg.
induction n.
now simpl.
simpl.
now apply Deriv_eta.
Qed.

Lemma Deriv_n_comp: forall f n m x,
  Deriv_n (Deriv_n f m) n x = Deriv_n f (n+m) x.
intros f n m.
induction n.
now simpl.
simpl.
now apply Deriv_eta.
Qed.

Lemma Schwarz_aux :
  forall f x y (eps : posreal),
  ( forall u v, Rabs (u - x) < eps -> Rabs (v - y) < eps ->
    ex_deriv (fun z => f z v) u /\
    ex_deriv (fun z => Deriv (fun t => f t z) u) v ) ->
  forall h k, Rabs h < eps -> Rabs k < eps ->
  let phi k x := f x (y + k) - f x y in
  exists u, exists v,
  Rabs (u - x) <= Rabs h /\ Rabs (v - y) <= Rabs k /\
  phi k (x + h) - phi k x = h * k * (Deriv (fun z => Deriv (fun t => f t z) u) v).
Proof.
intros f x y eps HD h k Hh Hk phi.
assert (Hx: x + h - x = h) by ring.
assert (Hy: y + k - y = k) by ring.
(* . *)
destruct (MVT_cor4 (phi k) x (Rabs h)) with (b := x + h) as (u&Hu1&Hu2).
intros c Hc.
apply ex_deriv_minus.
apply HD.
now apply Rle_lt_trans with (Rabs h).
now rewrite Hy.
apply HD.
now apply Rle_lt_trans with (Rabs h).
rewrite /Rminus Rplus_opp_r Rabs_R0.
apply cond_pos.
rewrite Hx.
apply Rle_refl.
rewrite Hx in Hu1, Hu2.
exists u.
(* . *)
destruct (MVT_cor4 (fun v => Deriv (fun t => f t v) u) y (Rabs k)) with (b := y + k) as (v&Hv1&Hv2).
intros c Hc.
apply HD.
now apply Rle_lt_trans with (Rabs h).
now apply Rle_lt_trans with (1 := Hc).
rewrite Hy.
apply Rle_refl.
rewrite Hy in Hv1, Hv2.
exists v.
(* . *)
refine (conj Hu2 (conj Hv2 _)).
rewrite Hu1 /phi Deriv_minus.
rewrite Hv1.
ring.
apply HD.
now apply Rle_lt_trans with (Rabs h).
now rewrite Hy.
apply HD.
now apply Rle_lt_trans with (Rabs h).
rewrite /Rminus Rplus_opp_r Rabs_R0.
apply cond_pos.
Qed.

Lemma Schwarz: forall f x y (eps : posreal),
   (forall u v, Rabs (u-x) < eps -> Rabs (v-y) < eps
          ->  ex_deriv (fun z => f z v) u /\
              ex_deriv (fun z => f u z) v /\
              ex_deriv (fun z => Deriv (fun t => f z t) v) u /\
              ex_deriv (fun z => Deriv (fun t => f t z) u) v)
    -> continuity2_pt (fun u v => Deriv (fun z => Deriv (fun t => f z t) v) u) x y
    -> continuity2_pt (fun u v => Deriv (fun z => Deriv (fun t => f t z) u) v) x y
    -> Deriv (fun z => Deriv (fun t => f z t) y) x = Deriv (fun z => Deriv (fun t => f t z) x) y.
Proof.
intros f x y eps HD HC2 HC1.
refine (let H1 := Schwarz_aux f x y eps _ in _).
intros u v Hu Hv.
split ; now apply HD.
refine (let H2 := Schwarz_aux (fun x y => f y x) y x eps _ in _).
intros u v Hu Hv.
split ; now apply HD.
simpl in H1, H2.
apply Req_lt_aux.
intros e.
destruct (HC1 (pos_div_2 e)) as (d1,Hc1).
destruct (HC2 (pos_div_2 e)) as (d2,Hc2).
set (d := Rmin (Rmin (pos_div_2 d1) (pos_div_2 d2)) (pos_div_2 eps)).
assert (Hd: d > 0).
apply Rmin_glb_lt.
apply Rmin_stable_in_posreal.
apply cond_pos.
assert (K: Rabs d < eps).
rewrite Rabs_right.
apply Rle_lt_trans with (1 := Rmin_r _ _).
apply (Rlt_eps2_eps eps).
apply cond_pos.
now apply Rgt_ge.
specialize (H1 d d K K).
specialize (H2 d d K K).
destruct H1 as (u1&v1&Hu1&Hv1&H1).
destruct H2 as (v2&u2&Hv2&Hu2&H2).
clear K.
rewrite (Rabs_right d (Rgt_ge _ _ Hd)) in Hu1 Hv1 Hu2 Hv2.
assert (K: forall a b, Rabs (a - b) <= d -> Rabs (a - b) < d1).
intros a b H.
apply Rle_lt_trans with (1 := H).
apply Rle_lt_trans with (1 := Rmin_l _ _).
apply Rle_lt_trans with (1 := Rmin_l _ _).
apply (Rlt_eps2_eps d1).
apply cond_pos.
specialize (Hc1 u1 v1 (K _ _ Hu1) (K _ _ Hv1)).
clear K.
assert (K: forall a b, Rabs (a - b) <= d -> Rabs (a - b) < d2).
intros a b H.
apply Rle_lt_trans with (1 := H).
apply Rle_lt_trans with (1 := Rmin_l _ _).
apply Rle_lt_trans with (1 := Rmin_r _ _).
apply (Rlt_eps2_eps d2).
apply cond_pos.
specialize (Hc2 u2 v2 (K _ _ Hu2) (K _ _ Hv2)).
clear -Hd H1 H2 Hc1 Hc2.
assert (H: forall a b c, b - c = -(a - b) + (a - c)) by (intros ; ring).
rewrite (H (Deriv (fun z : R => Deriv (fun t : R => f z t) v2) u2)).
clear H.
apply Rle_lt_trans with (1 := Rabs_triang _ _).
rewrite Rabs_Ropp (double_var e).
apply Rplus_lt_compat.
exact Hc2.
replace (Deriv (fun z : R => Deriv (fun t : R => f z t) v2) u2) with
  (Deriv (fun z : R => Deriv (fun t : R => f t z) u1) v1).
exact Hc1.
apply Rmult_eq_reg_l with (d * d).
rewrite -H1 -H2.
ring.
apply Rgt_not_eq.
now apply Rmult_gt_0_compat.
Qed.

Lemma is_deriv_eta: forall f1 f2 g t,
  (forall y, f1 y = f2 y) ->
  is_deriv f1 t g -> is_deriv f2 t g.
Proof.
intros f1 f2 g t H.
unfold is_deriv, derivable_pt_lim.
intros H1 eps He.
destruct (H1 eps He) as (d,Hd).
exists d; intros h Hh1 Hh2.
rewrite <- 2!H.
now apply Hd.
Qed.


Theorem Taylor_Lagrange :
  forall f n x y, x < y ->
  ( forall t, x <= t <= y -> forall k, (k <= S n)%nat -> ex_deriv_n f k t ) ->
  exists zeta, x < zeta < y /\
    f y =  sum_f_R0 (fun m => (y-x) ^ m / INR (fact m) * Deriv_n f m x )  n
        + (y-x) ^ (S n) / INR (fact (S n)) * Deriv_n f (S n) zeta.
Proof.
intros f n x y Hxy Df.
pose (c:= (f y - sum_f_R0 (fun m => (y-x) ^ m / INR (fact m) * Deriv_n f m x )  n)
                / (y-x) ^ (S n)).
pose (g t := f y - sum_f_R0 (fun m => (y-t) ^ m / INR (fact m) * Deriv_n f m t )  n
               - c * (y-t) ^ (S n)).
assert (Dg : forall t, x <= t <= y -> is_deriv g t
  (- (y-t) ^ n / INR (fact n) * Deriv_n f (S n) t + c * INR (S n) * (y-t) ^ n)).
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
apply derivable_pt_lim_plus.
(* . *)
clear c g.
rename n into N.
generalize (le_refl N).
generalize N at -2.
intros n.
induction n.
(* .. *)
intros _.
simpl.
replace (-1 / 1 * Deriv (fun x0 : R => f x0) t) with (0 - (1/1 *Deriv (fun x0 : R => f x0) t)) by field.
apply derivable_pt_lim_minus.
apply derivable_pt_lim_const.
apply derivable_pt_lim_scal.
rewrite (Deriv_eta _ f).
apply Deriv_prop.
apply (Df t Ht 1%nat).
apply le_n_S.
apply le_0_n.
easy.
(* .. *)
intros Hn.
apply is_deriv_eta with (fun x0 : R =>
   (f y -
   (sum_f_R0 (fun m : nat => (y - x0) ^ m / INR (fact m) * Deriv_n f m x0) n)) -
    (y - x0) ^ (S n) / INR (fact (S n)) *
     Deriv_n f (S n) x0).
simpl.
intros; ring.
replace (- (y - t) ^ S n / INR (fact (S n)) * Deriv_n f (S (S n)) t) with
  ((- (y - t) ^ n / INR (fact n) * Deriv_n f (S n) t) -
      (- (y - t) ^ n / INR (fact n) * (Deriv_n f (S n) t) + 
       ( (y - t) ^ S n / INR (fact (S n)) * Deriv_n f (S (S n)) t))).
2: rewrite /Rdiv Ropp_mult_distr_l_reverse ; ring.
apply derivable_pt_lim_plus.
apply IHn.
now apply lt_le_weak.
apply derivable_pt_lim_opp.
apply (derivable_pt_lim_mult (fun x0 => ((y - x0) ^ S n / INR (fact (S n)))) 
  (fun x0 => Deriv_n f (S n) x0)).
replace (- (y - t) ^ n / INR (fact n)) with
   (/ INR (fact (S n)) * (INR (S n)*(y - t) ^ n*(0-1))).
apply is_deriv_eta with (fun x0 : R => (/ INR (fact (S n)) * (y - x0) ^ S n)).
intros; unfold Rdiv; apply Rmult_comm.
now apply derivable_pt_lim_scal.
change (fact (S n)) with ((S n)*fact n)%nat.
rewrite mult_INR.
field.
split.
apply INR_fact_neq_0.
now apply not_0_INR.
apply Deriv_prop.
apply (Df t Ht (S (S n))).
now apply le_n_S.
(* . *)
apply is_deriv_eta with (fun x0 : R => -c * (y - x0) ^ S n).
intros; ring.
replace (c * INR (S n) * (y - t) ^ n) with ((-c) * ((INR (S n) * (y - t) ^ n) * (0-1))) by ring.
now apply derivable_pt_lim_scal.
(* *)
assert (Dg' : forall t : R, x <= t <= y -> derivable_pt g t).
intros t Ht.
exists (Deriv g t).
apply Deriv_prop.
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
replace (/ INR (fact (S n)) * Deriv_n f (S n) zeta) with c.
unfold c.
now field.
apply Rmult_eq_reg_r with (INR (S n) * (y - zeta) ^ n).
apply Rplus_eq_reg_l with ((- (y - zeta) ^ n / INR (fact n) * Deriv_n f (S n) zeta)).
change (fact (S n)) with (S n * fact n)%nat.
rewrite mult_INR.
apply trans_eq with R0.
rewrite -Rmult_assoc.
assert (H: x <= zeta <= y) by (split ; apply Rlt_le ; apply Hzeta1).
rewrite -(Deriv_correct _ _ _ (Dg _ H)).
destruct (pr zeta Hzeta1) as (x0,Hd).
simpl in Hzeta2.
rewrite Hzeta2 in Hd.
now apply Deriv_correct.
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

Theorem is_deriv_SF:
  forall (fn : nat -> R -> R) (N : nat) (x : R),
  (forall n : nat, (n <= N)%nat -> ex_deriv (fn n) x) ->
  is_deriv (fun y : R => sum_f_R0 (fun k : nat => fn k y) N) x (sum_f_R0 (fun k => Deriv (fn k) x) N).
intros fn; induction N.
intros x H; simpl.
apply is_deriv_eta with (fn 0%nat).
easy.
apply Deriv_prop.
now apply H.
intros x H.
simpl.
apply derivable_pt_lim_plus.
apply IHN.
intros; apply H.
now apply le_S.
apply Deriv_prop.
now apply H.
Qed.



Theorem Taylor_Lagrange_2D : forall f n x y,
   ex_diff_n f (S n) x y -> DL_regular_n f n x y.
Proof.
intros f n x y Df.
assert (exists D, exists delta : posreal, forall u v, Rabs (u - x) < delta -> Rabs (v - y) < delta ->
  forall p, (p <= S n)%nat ->
  Rabs (partial_derive p (S n - p) f u v) <= D).
admit. (* continuité 2D => borné *)
destruct H as (D,(delta,H)).
exists  (/ INR (fact (S n)) * D * sum_f_R0 (fun i : nat => Rabs (C (S n) i)) (S n)).
exists delta.
intros u v Hu Hv.
(* specialize (H u v Hu Hv).*)
set (g t := f (x + t * (u - x)) (y + t * (v - y))).
replace (f u v) with (g 1) by (rewrite /g 2!Rmult_1_l ; apply f_equal2 ; ring).
assert (forall k t, (k <= S n)%nat -> 0 <= t <= 1 -> is_deriv_n g k t (sum_f_R0 (fun m =>  C k m * partial_derive m (k - m)%nat f (x+t*(u-x)) (y+t*(v-y)) *
         (u-x) ^ m * (v-y) ^ (k - m)%nat) k)).
induction k.
simpl.
unfold C, partial_derive, g.
simpl.
intros ; field.
intros t Hk Ht.
simpl (Deriv_n g (S k) t).
unfold is_deriv_n.
apply is_deriv_eta with (fun t => sum_f_R0
           (fun m : nat =>
            C k m *
            partial_derive m (k - m) f (x + t * (u - x)) (y + t * (v - y)) *
            (u - x) ^ m * (v - y) ^ (k - m)) k).
intros y0.
apply sym_eq.
apply Deriv_n_correct.
apply IHk.
now apply lt_le_weak.
admit. (* faux *)
admit. (* dérivée du DL *)

destruct (Taylor_Lagrange g n 0 1 Rlt_0_1) as (t&Ht&Hg).
intros t Ht.
intros [|k] Hk.
easy.
eexists.
now apply (H0 (S k)).
rewrite Hg /DL_pol.
replace (1 - 0) with 1 by ring.
rewrite pow1 {1}/Rminus Rplus_assoc [_*_+_]Rplus_comm -Rplus_assoc -/(Rminus _ _).
assert (forall k t, (k <= S n)%nat -> 0 <= t <= 1 -> Deriv_n g k t = 
      (sum_f_R0 (fun m =>  C k m * partial_derive m (k - m)%nat f (x+t*(u-x)) (y+t*(v-y)) *
         (u-x) ^ m * (v-y) ^ (k - m)%nat) k)).
intros k t0 Hk Ht0.
apply Deriv_n_correct.
now apply H0.
rewrite -minus_sum sum_eq_R0.
rewrite H1.
rewrite Rplus_0_l.
unfold differential.
rewrite Rabs_mult.
eapply Rle_trans.
apply Rmult_le_compat_l.
apply Rabs_pos.
eapply Rle_trans.
apply Rsum_abs.
apply sum_Rle.
intros n0 Hn0.
rewrite Rmult_assoc 3!Rabs_mult.
rewrite Rmult_assoc.
apply Rmult_le_compat_l.
apply Rabs_pos.
apply Rmult_le_compat.
apply Rabs_pos.
apply Rmult_le_pos; apply Rabs_pos.
apply H.
admit. (* facile *)
admit. (* facile *)
exact Hn0.
rewrite - 2!RPow_abs.
instantiate (1:=(Rmax (Rabs (u - x)) (Rabs (v - y)) ^ S n)).
admit. (* bof *)
rewrite - scal_sum.
rewrite /Rdiv Rmult_1_l Rabs_right .
right; ring.
apply Rle_ge; apply Rlt_le; apply Rinv_0_lt_compat.
apply INR_fact_lt_0.
apply le_refl.
split; apply Rlt_le, Ht.
intros n0 hn0.
rewrite H1.
rewrite 2!Rmult_0_l 2!Rplus_0_r pow1.
unfold differential, Rdiv; ring.
now apply le_S.
split; [apply Rle_refl | apply Rle_0_1].
Qed.
