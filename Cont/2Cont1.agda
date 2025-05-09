{-# OPTIONS --type-in-type #-}

module Cont.2Cont1 where

open import Cont.CCont
open import Cont.1Cont

open Cat

record 2Cont : Set

record 2ContHom (C D : 2Cont) : Set

2CONT : Cat

{-# NO_POSITIVITY_CHECK #-}
record 2Cont where
  inductive
  field
    S : Set
    P₀ : S → Cont 2CONT
    P₁ : S → Set    

record 2ContHom C D where
  inductive
  eta-equality
  open 2Cont
  field
    f : C .S → D .S
    g₀ : (s : C .S) → ContHom 2CONT (D .P₀ (f s)) (C .P₀ s)
    g₁ : (s : C .S) → D .P₁ (f s) → C .P₁ s

{-# TERMINATING #-}
2CONT = record
  { Obj = 2Cont
  ; Hom = 2ContHom
  ; id = record
    { f = id'
    ; g₀ = λ s → id' ◃ λ s₁ → 2CONT .id
    ; g₁ = λ s → id'
    }
  ; _∘_ = λ δ γ → record
    { f = δ .2ContHom.f ∘' γ .2ContHom.f
    ; g₀ = λ s → γ .2ContHom.g₀ s .ContHom.f ∘' (δ .2ContHom.g₀ (γ .2ContHom.f s) .ContHom.f)
         ◃ λ s₁ → 2CONT ._∘_ (δ .2ContHom.g₀ (γ .2ContHom.f s) .ContHom.g s₁) (γ .2ContHom.g₀ s .ContHom.g (δ .2ContHom.g₀ (γ .2ContHom.f s) .ContHom.f s₁))
    ; g₁ = λ s → γ .2ContHom.g₁ s ∘' (δ .2ContHom.g₁ (γ .2ContHom.f s))
    }
  }

{-# NO_POSITIVITY_CHECK #-}
record 2⟦_⟧ (C : 2Cont) (F : 1Cont) (X : Set) : Set where
  inductive
  eta-equality
  open 2Cont C
  field
    s : S
    k₀ : (p : P₀ s .Cont.S) → ⟦ F ⟧ (2⟦ P₀ s .Cont.P p ⟧ F X)
    k₁ : P₁ s → X

{-# TERMINATING #-}
2⟦_⟧₁ : (C : 2Cont)
  → {F G : 1Cont} → (∀ X → ⟦ F ⟧ X → ⟦ G ⟧ X)
  → {X Y : Set} → (X → Y)
  → 2⟦ C ⟧ F X → 2⟦ C ⟧ G Y
2⟦ C ⟧₁ {F} {G} α {X} {Y} f record { s = s ; k₀ = k₀ ; k₁ = k₁ } =
  record
  { s = s
  ; k₀ = λ p → α (2⟦ (P₀ C s) .P p ⟧ G Y) (⟦ F ⟧₁ (2⟦ (P₀ C s) .P p ⟧₁ α f) (k₀ p))
  ; k₁ = f ∘' k₁
  }
  where
    open 2Cont
    open Cont

{-# TERMINATING #-}
2⟦_⟧Hom : {C D : 2Cont} → 2ContHom C D
  → (F : 1Cont) (X : Set)
  → 2⟦ C ⟧ F X → 2⟦ D ⟧ F X
2⟦ record { f = f ; g₀ = g₀ ; g₁ = g₁ } ⟧Hom F X
  record { s = s ; k₀ = k₀ ; k₁ = k₁ } = record
  { s = f s
  ; k₀ = λ p → ⟦ F ⟧₁ (2⟦ g₀ s .ContHom.g p ⟧Hom F X) (k₀ (g₀ s .ContHom.f p))
  ; k₁ = k₁ ∘' g₁ s
  }
