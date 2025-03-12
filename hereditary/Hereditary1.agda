module Hereditary1 where

data Ty : Set where
  ∘ : Ty
  _⇒_ : Ty → Ty → Ty

variable A B C : Ty

data Con : Set where
  ∙ : Con
  _▹_ : Con → Ty → Con

variable Γ Δ : Con

data Var : Con → Ty → Set where
  vz : Var (Γ ▹ A) A
  vs : Var Γ A → Var (Γ ▹ B) A

variable x y z : Var Γ A

data Tm : Con → Ty → Set where
  var : Var Γ A → Tm Γ A
  lam : Tm (Γ ▹ A) B → Tm Γ (A ⇒ B)
  app : Tm Γ (A ⇒ B) → Tm Γ A → Tm Γ B

variable t u : Tm Γ A

_-_ : (Γ : Con) → Var Γ A → Con
(Γ ▹ A) - vz = Γ
(Γ ▹ A) - vs x = (Γ - x) ▹ A

wkVar : (x : Var Γ A) → Var (Γ - x) B → Var Γ B
wkVar vz y = vs y
wkVar (vs x) vz = vz
wkVar (vs x) (vs y) = vs (wkVar x y)

wkTm : (x : Var Γ A) → Tm (Γ - x) B → Tm Γ B
wkTm x (var v) = var (wkVar x v)
wkTm x (lam t) = lam (wkTm (vs x) t)
wkTm x (app t u) = app (wkTm x t) (wkTm x u)

data EqVar : Var Γ A → Var Γ B → Set where
  same : EqVar x x
  diff : (x : Var Γ A) (y : Var (Γ - x) B) → EqVar x (wkVar x y)

eq : (x : Var Γ A) (y : Var Γ B) → EqVar x y
eq vz vz = same
eq vz (vs y) = diff vz y
eq (vs x) vz = diff (vs x) vz
eq (vs x) (vs y) with eq x y
... | same = same
... | diff .x y = diff (vs x) (vs y)

{-
substVar : Var Γ B → (x : Var Γ A) → Tm (Γ - x) A → Tm (Γ - x) B
substVar v x u with eq x v
... | same = u
... | diff v x = var x

substTm : Tm Γ B → (x : Var Γ A) → Tm (Γ - x) A → Tm (Γ - x) B
substTm (var v) x u = substVar v x u
substTm (lam t) x u = lam (substTm t (vs x) (wkTm vz u))
substTm (app t₁ t₂) x u = app (substTm t₁ x u) (substTm t₂ x u)

data _≡_ : Tm Γ A → Tm Γ A → Set where
  refl : t ≡ t
  sym  : t ≡ u → u ≡ t
  trans : t ≡ u → u ≡  → t ≡ t₂
  ap-lam : t ≡ u → lam t ≡ lam u
  ap-app : t₁ ≡ t₂ → u₁ ≡ u₂ → app t₁ u₁ ≡ app t₂ u₂
  β : app (lam t) u ≡ substTm t vz u
  η : lam (app (wkTm vz t) (var vz)) ≡ t
-}

-- Normal Form

data Nf : Con → Ty → Set

data Ne : Con → Set

data Sp : Con → Ty → Set

data Nf where
  lam : Nf (Γ ▹ A) B → Nf Γ (A ⇒ B)
  ne  : Ne Γ → Nf Γ ∘

data Ne where
  _,_ : Var Γ A → Sp Γ A → Ne Γ

data Sp where
  ε   : Sp Γ ∘
  _,_ : Nf Γ A → Sp Γ B → Sp Γ (A ⇒ B)
  
-- λf.λz.f (f z)
exnf : Nf ∙ ((∘ ⇒ ∘) ⇒ (∘ ⇒ ∘))
exnf = lam (lam (ne (vs vz , (ne (vs vz , (ne (vz , ε) , ε)) , ε))))

-- Embedding

embNf : Nf Γ A → Tm Γ A

embNe : Ne Γ → Tm Γ ∘

embSp : Tm Γ A → Sp Γ A → Tm Γ ∘

embNf (lam n) = lam (embNf n)
embNf (ne e) = embNe e

embNe (v , sp) = embSp (var v) sp

embSp t ε = t
embSp t (n , ns) = embSp (app t (embNf n)) ns

wkNf : (x : Var Γ A) → Nf (Γ - x) B → Nf Γ B
wkNe : (x : Var Γ A) → Ne (Γ - x) → Ne Γ
wkSp : (x : Var Γ A) → Sp (Γ - x) B → Sp Γ B

wkNf x (lam n) = lam (wkNf (vs x) n)
wkNf x (ne e) = ne (wkNe x e)

wkNe x (v , sp) = wkVar x v , wkSp x sp

wkSp x ε = ε
wkSp x (n , ns) = wkNf x n , wkSp x ns

appTy : Ty → Ty → Ty
appTy ∘ A = A ⇒ ∘
appTy (A ⇒ B) C = A ⇒ appTy B C

appSp : Sp Γ A → Nf Γ B → Sp Γ (appTy A B)
appSp ε u = u , ε
appSp (t , ts) u = t , appSp ts u

-- η-expansion

-- Normalization

nApp : Nf Γ (A ⇒ B) → Nf Γ A → Nf Γ B

_[_:=_] : Nf Γ A → (x : Var Γ B) → Nf (Γ - x) B → Nf (Γ - x) A

_<_:=_> : Sp Γ A → (x : Var Γ B) → Nf (Γ - x) B → Sp (Γ - x) A

_◇_ : Nf Γ A → Sp Γ A → Ne Γ

nApp (lam t) u = t [ vz := u ]

(lam t) [ x := u ] = lam (t [ vs x := wkNf vz u ])
(ne (y , ts)) [ x := u ] with eq x y
... | same = ne (u ◇ (ts < x := u >))
... | diff .x y' = ne (y' , (ts < x := u >))

ε < x := u > = ε
(t , ts) < x := u > = (t [ x := u ]) , (ts < x := u >)

(ne x) ◇ ε = x
(lam t) ◇ (u , us) = nApp (lam t) u ◇ us

nTm : Tm ∙ A → Nf ∙ A
nTm (lam x) = lam {!!}
nTm (app t u) = nApp (nTm t) (nTm u)

-- λx.x
ex1 : Nf ∙ ((∘ ⇒ ∘) ⇒ (∘ ⇒ ∘))
ex1 = lam {!ne!}

