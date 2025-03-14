{-# OPTIONS --type-in-type #-}

module Cont.HCont2 where

open import Data.Product
open import Data.Sum
open import Data.Unit
open import Data.Empty
open import Relation.Binary.PropositionalEquality

{- Syntax -}

infixr 20 _⇒_
data Ty : Set where
  ∘ : Ty
  _⇒_ : Ty → Ty → Ty

data Con : Set where
  ∙   : Con
  _▹_ : Con → Ty → Con

infixl 5 _▹_

variable A B C : Ty
variable Γ Δ : Con

data Var : Con → Ty → Set where
  zero : Var (Γ ▹ A) A
  suc  : Var Γ A → Var (Γ ▹ B) A

data HCont-NF : Con → Ty → Set

record HCont-NE (Γ : Con) : Set

data HCont-SP : Con → Ty → Set

data HCont-NF where
  lam : HCont-NF (Γ ▹ A) B → HCont-NF Γ (A ⇒ B)
  ne  : HCont-NE Γ → HCont-NF Γ ∘

record HCont-NE Γ where
  inductive
  field
    S : Set
    P : S → Var Γ A → Set
    R : (s : S) (x : Var Γ A) (p : P s x) → HCont-SP Γ A

data HCont-SP where
  ε   : HCont-SP Γ ∘
  _,_ : HCont-NF Γ A → HCont-SP Γ B → HCont-SP Γ (A ⇒ B)

HCont : Ty → Set
HCont A = HCont-NF ∙ A

H : (Set → Set) → (Set → Set)
H F A = A × F (F A)

BCont : HCont ((∘ ⇒ ∘) ⇒ ∘ ⇒ ∘)
BCont = lam (lam (ne (record { S = S ; P = P ; R = R })))
  where
  Γ₀ : Con
  Γ₀ = ∙ ▹ ∘ ⇒ ∘ ▹ ∘

  NF-A : HCont-NF Γ₀ ∘
  NF-A = ne (record { S = S ; P = P ; R = R })
    where
    S : Set
    S = ⊤

    P : S → Var Γ₀ A → Set
    P tt zero = ⊤
    P tt (suc zero) = ⊥

    R : (s : S) (x : Var Γ₀ A) → P s x → HCont-SP Γ₀ A
    R tt zero tt = ε
    R tt (suc zero) ()
  
  NF-FA : HCont-NF Γ₀ ∘
  NF-FA = ne (record { S = S ; P = P ; R = R })
    where
    S : Set
    S = ⊤

    P : S → Var Γ₀ A → Set
    P tt zero = ⊥
    P tt (suc zero) = ⊤

    R : (s : S) (x : Var Γ₀ A) → P s x → HCont-SP Γ₀ A
    R tt zero ()
    R tt (suc zero) tt = NF-A , ε

  
  S : Set
  S = ⊤

  P : S → Var Γ₀ A → Set
  P tt zero = ⊤
  P tt (suc zero) = ⊤

  R : (s : S) (x : Var Γ₀ A) → P s x → HCont-SP Γ₀ A
  R tt zero tt = ε
  R tt (suc zero) tt = NF-FA , ε


----

open import Cont.Cont

HCont→Cont : HCont (∘ ⇒ ∘) → Cont
HCont→Cont (lam (ne record { S = S ; P = P ; R = R })) = S ◃ λ s → P s zero

Cont→HCont : Cont → HCont (∘ ⇒ ∘)
Cont→HCont (S ◃ P) = lam (ne (record { S = S ; P = λ{ s zero → P s } ; R = λ{ s zero p → ε } }))

----

⟦_⟧T : Ty → Set
⟦ ∘ ⟧T = Set
⟦ A ⇒ B ⟧T = ⟦ A ⟧T → ⟦ B ⟧T

⟦_⟧C : Con → Set
⟦ ∙ ⟧C = ⊤
⟦ Γ ▹ A ⟧C = ⟦ Γ ⟧C × ⟦ A ⟧T

⟦_⟧v : Var Γ A → ⟦ Γ ⟧C → ⟦ A ⟧T
⟦ zero ⟧v (γ , a) = a
⟦ suc x ⟧v (γ , a) = ⟦ x ⟧v γ

⟦_⟧nf : HCont-NF Γ A → ⟦ Γ ⟧C → ⟦ A ⟧T
⟦_⟧ne : HCont-NE Γ → ⟦ Γ ⟧C → Set
⟦_⟧sp : HCont-SP Γ A → ⟦ Γ ⟧C → ⟦ A ⟧T → Set

⟦ lam x ⟧nf γ a = ⟦ x ⟧nf (γ , a)
⟦ ne x ⟧nf γ = ⟦ x ⟧ne γ

⟦_⟧ne {Γ} record { S = S ; P = P ; R = R } γ =
  Σ[ s ∈ S ] ({A : Ty} (x : Var Γ A) (p : P s x) → ⟦ R s x p ⟧sp γ (⟦ x ⟧v γ))

⟦ ε ⟧sp γ a = a
⟦ n , ns ⟧sp γ f = ⟦ ns ⟧sp γ (f (⟦ n ⟧nf γ))

⟦_⟧hcont : HCont A → ⟦ A ⟧T
⟦ x ⟧hcont = ⟦ x ⟧nf tt

B-HCont : (Set → Set) → Set → Set
B-HCont = ⟦ BCont ⟧hcont

{-
= ⟦ lam (lam (ne (record { S = S ; P = P ; R = R }))) ⟧hcont
= ⟦ lam (lam (ne (record { S = S ; P = P ; R = R }))) ⟧nf tt
= λ F → ⟦ lam (ne (record { S = S ; P = P ; R = R })) ⟧nf (tt , F)
= λ F X → ⟦ ne (record { S = S ; P = P ; R = R }) ⟧nf (tt , F , X)
= λ F X → ⟦ record { S = S ; P = P ; R = R } ⟧ne (tt , F , X)
= λ F X → ⟦ record { S = S ; P = P ; R = R } ⟧ne (tt , F , A)
= λ F X → Σ[ s ∈ S ] ((x : Var Γ A) (p : P s x) → ⟦ R s x p ⟧sp γ (⟦ x ⟧v γ))   # γ = tt , F , X

  Σ[ s ∈ S ] ((x : Var Γ A) (p : P s x) → ⟦ R s x p ⟧sp γ (⟦ x ⟧v γ))
= ((x : Var Γ A) (p : P s x) → ⟦ R s x p ⟧sp γ (⟦ x ⟧v γ))                # S = ⊤
= ⟦ R tt zero tt ⟧sp γ (⟦ zero ⟧v γ) × ⟦ R tt one tt ⟧sp γ (⟦ one ⟧v γ))  # P tt zero = ⊤ , P tt one = ⊤
= ⟦ ε ⟧sp γ (⟦ zero ⟧v γ) × ⟦ ne FFA , ε ⟧sp γ (⟦ one ⟧v γ)               # R ...
= ⟦ zero ⟧v γ × ⟦ ε ⟧sp γ (⟦ one ⟧v γ (⟦ ne NE-FA ⟧nf γ))
= X × ⟦ one ⟧v γ (⟦ ne NE-FA ⟧nf γ)
= X × F (⟦ ne NE-FA ⟧nf γ)
= X × F (⟦ NE-FA ⟧ne γ)

  ⟦ NE-FA ⟧ne γ
= ⟦ record { S = S ; P = P ; R = R } ⟧ne γ
= Σ[ s ∈ S ] ((x : Var Γ A) (p : P s x) → ⟦ R s x p ⟧sp γ (⟦ x ⟧v γ))   # by definition of S , P , R
= ⟦ ne NE-A , ε ⟧sp γ (⟦ one ⟧v γ)
= ⟦ ε ⟧sp γ (⟦ one ⟧v γ (⟦ ne NE-A ⟧nf γ))
= ⟦ one ⟧v γ (⟦ ne NE-A ⟧nf γ)
= F (⟦ ne NE-A ⟧nf γ)

  ⟦ ne NE-A ⟧nf γ
= ⟦ record { S = S ; P = P ; R = R } ⟧ne γ
= Σ[ s ∈ S ] ((x : Var Γ A) (p : P s x) → ⟦ R s x p ⟧sp γ (⟦ x ⟧v γ))   # by definition of S , P , R
= ⟦ ε ⟧γ (⟦ zero ⟧v γ)
= ⟦ zero ⟧v γ
= A
-}


---

WOW : ((Set → Set) → Set → Set) → (Set → Set) → Set → Set
WOW H F X = H F X

WOW-HCont : HCont (((∘ ⇒ ∘) ⇒ ∘ ⇒ ∘) ⇒ (∘ ⇒ ∘) ⇒ ∘ ⇒ ∘)
WOW-HCont = lam (lam (lam (ne (record { S = S ; P = P ; R = R }))))
  where
  Γ₀ : Con
  Γ₀ = ∙ ▹ (∘ ⇒ ∘) ⇒ ∘ ⇒ ∘ ▹ ∘ ⇒ ∘ ▹ ∘
  
  S : Set
  S = ⊤

  P : S → Var Γ₀ A → Set
  P tt zero = ⊥
  P tt (suc zero) = ⊥
  P tt (suc (suc zero)) = ⊤

  R : (s : S) (x : Var Γ₀ A) → P s x → HCont-SP Γ₀ A
  R tt (suc (suc zero)) tt = F-NF , X-NF , ε
    where
    F-NF : HCont-NF Γ₀ (∘ ⇒ ∘)
    F-NF = lam (ne (record { S = F-S ; P = F-P ; R = F-R }))
      where
      F-S : Set
      F-S = ⊤

      F-P : F-S → Var (Γ₀ ▹ ∘) A → Set
      F-P tt zero = ⊥
      F-P tt (suc zero) = ⊥
      F-P tt (suc (suc zero)) = ⊤
      F-P tt (suc (suc (suc zero))) = ⊥

      F-R : (s : F-S) (x : Var (Γ₀ ▹ ∘) A) → F-P s x → HCont-SP (Γ₀ ▹ ∘) A
      F-R tt (suc (suc zero)) tt = Y-NF , ε
        where
        Y-NF : HCont-NF (Γ₀ ▹ ∘) ∘
        Y-NF = ne (record { S = Y-S ; P = Y-P ; R = Y-R })
          where
          Y-S : Set
          Y-S = ⊤

          Y-P : Y-S → Var (Γ₀ ▹ ∘) A → Set
          Y-P tt zero = ⊤
          Y-P tt (suc x) = ⊥

          Y-R : (s : Y-S) (x : Var (Γ₀ ▹ ∘) A) → Y-P s x → HCont-SP (Γ₀ ▹ ∘) A
          Y-R tt zero tt = ε
      F-R tt (suc (suc (suc zero))) ()

    
    X-NF : HCont-NF Γ₀ ∘
    X-NF = ne (record { S = X-S ; P = X-P ; R = X-R })
      where
      X-S : Set
      X-S = ⊤

      X-P : X-S → Var Γ₀ A → Set
      X-P tt zero = ⊤
      X-P tt (suc x) = ⊥

      X-R : (s : X-S) (x : Var Γ₀ A) → X-P s x → HCont-SP Γ₀ A
      X-R tt zero tt = ε

app : HCont-NF Γ (A ⇒ B) → HCont-NF (Γ ▹ A) B
app (lam x) = x

zero-NE : HCont-NE (Γ ▹ ∘)
zero-NE = record { S = S ; P = P ; R = R }
  where
  S : Set
  S = ⊤

  P : S → Var (Γ ▹ ∘) A → Set
  P tt zero = ⊤
  P tt (suc x) = ⊥

  R : (s : S) (x : Var (Γ ▹ ∘) A) → P s x → HCont-SP (Γ ▹ ∘) A
  R tt zero tt = ε

zero-NF : HCont-NF (Γ ▹ A) A
suc-NF  : HCont-NF Γ A → HCont-NF (Γ ▹ B) A

zero-NF {Γ} {∘} = ne zero-NE
zero-NF {Γ} {A ⇒ B} = lam {!!}

suc-NF (lam x) = lam {!!}
suc-NF (ne x) = {!!}
