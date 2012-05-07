Require Export Reals Arithmetique Markov Sup_seq ssreflect.
Open Scope R_scope.

(** * Limit sequence *)

Definition Lim_seq (u : nat -> R) : R := real (LimSup_seq u).
Definition is_lim_seq (u : nat -> R) (l : R) :=
  forall eps : posreal, exists N : nat, forall n : nat,
    (N <= n)%nat -> Rabs (u n - l) < eps.
Definition ex_lim_seq (u : nat -> R) :=
  exists l, is_lim_seq u l.

Lemma is_lim_seq_correct (u : nat -> R) (l : R) :
  is_lim_seq u l <-> Rbar_is_lim_seq (fun n => Finite (u n)) (Finite l).
Proof.
  split => /= Hl eps ; case: (Hl eps) => {Hl} N Hl ; exists N => n Hn ;
  by apply Rabs_lt_encadre_cor, Hl.
Qed.
Lemma Lim_seq_correct (u : nat -> R) :
  Lim_seq u = real (Rbar_lim_seq (fun n => Finite (u n))).
Proof.
  rewrite /Lim_seq /Rbar_lim_seq.
  by rewrite (LimSup_seq_correct u).
Qed.

(** ** Compute limit *)

Lemma Lim_seq_rw (u : nat -> R) :
  forall l, is_lim_seq u l -> Lim_seq u = l.
Proof.
  move => l ; move/is_lim_seq_correct => Hl ; rewrite Lim_seq_correct ;
  by rewrite (Rbar_is_lim_correct _ _ Hl).
Qed.
Lemma Lim_seq_prop (u : nat -> R) :
  ex_lim_seq u -> is_lim_seq u (Lim_seq u).
Proof.
  intros (l,H).
  cut (Lim_seq u = l).
    intros ; rewrite H0 ; apply H.
  apply Lim_seq_rw, H.
Qed.

(** * Operations *)

Lemma is_lim_seq_CL (u v : nat -> R) (a l1 l2 : R) {l : R} :
  is_lim_seq u l1 -> is_lim_seq v l2 -> l = l1 + a * l2 ->
    is_lim_seq (fun n => u n + a * v n) l.
Proof.
  intros Hf Hg Hl e0 ; rewrite Hl ; clear Hl.
  assert (He : 0 < e0 / (1 + Rabs a)).
    unfold Rdiv ; apply Rmult_lt_0_compat ; [apply e0 | apply Rinv_0_lt_compat] ;
    apply Rlt_le_trans with (1 := Rlt_0_1) ; rewrite -{1}(Rplus_0_r 1) ;
    apply Rplus_le_compat_l, Rabs_pos.
  set (eps := mkposreal _ He).
  move: (Hf eps) => {Hf} [Nf Hf].
  move: (Hg eps) => {Hg} [Ng Hg].
  exists (Nf+Ng)%nat ; intros.
  assert (Rw : u n + a * v n - (l1 + a * l2) = (u n - l1) + a * (v n - l2)) ; 
  [ ring | rewrite Rw ; clear Rw].
  assert (Rw : (pos e0) = eps + Rabs a * eps) ;
  [ simpl ; field ; apply Rgt_not_eq, Rlt_le_trans with (1 := Rlt_0_1) ; 
    rewrite -{1}(Rplus_0_r 1) ; apply Rplus_le_compat_l, Rabs_pos
  | rewrite Rw ; clear Rw].
  apply Rle_lt_trans with (1 := Rabs_triang _ _).
  apply Rplus_lt_le_compat.
  apply Hf, le_trans with (2 := H) ; intuition.
  rewrite Rabs_mult ; apply Rmult_le_compat_l.
  apply Rabs_pos.
  apply Rlt_le, Hg, le_trans with (2 := H) ; intuition.
Qed.
Lemma ex_lim_seq_CL (u v : nat -> R) (a : R) :
  ex_lim_seq u -> ex_lim_seq v -> ex_lim_seq (fun n => u n + a * v n).
Proof.
  intros (lf,Hf) (lg,Hg).
  exists (lf + a * lg) ; apply (is_lim_seq_CL u v a lf lg) ; [apply Hf | apply Hg | ring].
Qed.
Lemma Lim_seq_CL (u v : nat -> R) (a : R) :
  ex_lim_seq u -> ex_lim_seq v -> Lim_seq (fun n => u n + a * v n) = Lim_seq u + a * Lim_seq v.
Proof.
  intros.
  apply Lim_seq_rw.
  apply (is_lim_seq_CL _ _ _ (Lim_seq u) (Lim_seq v)).
  apply Lim_seq_prop, H.
  apply Lim_seq_prop, H0.
  reflexivity.
Qed.

Lemma is_lim_seq_plus (u v : nat -> R) {l : R} (l1 l2 : R) :
  is_lim_seq u l1 -> is_lim_seq v l2 -> l = l1 + l2 ->
    is_lim_seq (fun n => u n + v n) l.
Proof.
  intros.
  rewrite H1 ; clear H1 ; intros eps.
  assert (He2 : 0 < eps / 2) ; 
    [unfold Rdiv ; destruct eps ; apply Rmult_lt_0_compat ; intuition | ].
  elim (H (mkposreal _ He2)) ; clear H ; simpl ; intros N1 H.
  elim (H0 (mkposreal _ He2)) ; clear H0 ; simpl ; intros N2 H0.
  exists (N1+N2)%nat ; intros.
  assert (Rw : (u n + v n - (l1 + l2)) = (u n - l1) + (v n - l2)) ;
    [ring | rewrite Rw ; clear Rw].
  apply Rle_lt_trans with (1 := Rabs_triang _ _).
  rewrite (double_var eps) ; apply Rplus_lt_compat ; intuition.
Qed.
Lemma Lim_seq_plus (u v : nat -> R) :
  let w := fun n => u n + v n in
  ex_lim_seq u -> ex_lim_seq v -> Lim_seq w = Lim_seq u + Lim_seq v.
Proof.
  intros w (l1,Hu) (l2,Hv).
  apply Lim_seq_rw.
  rewrite (Lim_seq_rw _ _ Hu).
  rewrite (Lim_seq_rw _ _ Hv).
  apply is_lim_seq_plus with (l1 := l1) (l2 := l2) ; intuition.
Qed.

Lemma is_lim_seq_const {a : R} :
  is_lim_seq (fun n => a) a.
Proof.
  intros eps ; exists O ; intros.
  unfold Rminus ; rewrite (Rplus_opp_r a) Rabs_R0 ; apply eps.
Qed.
Lemma Lim_seq_const (a : R) :
  Lim_seq (fun n => a) = a.
Proof.
  intros.
  apply Lim_seq_rw.
  apply is_lim_seq_const.
Qed.
Lemma is_lim_seq_inv_n :
  is_lim_seq (fun n => /INR n) 0.
Proof.
  intros eps.
  assert (He : 0 <= /eps) ; 
    [apply Rlt_le, Rinv_0_lt_compat, eps|].
  destruct (nfloor_ex _ He) as (N,HN).
  exists (S N) ; intros.
  assert (Rw : (pos eps) = INR n * (eps / INR n)) ; 
    [field ; apply Rgt_not_eq, Rlt_gt, lt_0_INR, lt_le_trans with (2 := H), lt_O_Sn 
    | rewrite Rw ; clear Rw].
  assert (Rw : Rabs (/ INR n - 0) = /eps * (eps/INR n)) ; 
    [rewrite Rminus_0_r Rabs_right ; intuition ; field ; split ; 
    [ apply Rgt_not_eq ; intuition | apply Rgt_not_eq, eps ]
    | rewrite Rw ; clear Rw ].
  apply Rmult_lt_compat_r.
  unfold Rdiv ; apply Rmult_lt_0_compat ; intuition ; apply eps.
  apply Rlt_le_trans with (1 := proj2 HN).
  rewrite <- S_INR ; apply le_INR, H.
Qed.
Lemma Lim_seq_inv_n (a : R) :
  Lim_seq (fun n => /INR n) = 0.
Proof.
  intros.
  apply Lim_seq_rw.
  apply is_lim_seq_inv_n.
Qed.