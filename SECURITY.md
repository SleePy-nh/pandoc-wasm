# SECURITY.md - Aspects de sécurité des patches

> Documentation des modifications apportées aux packages Haskell pour la compilation WASM et leurs implications de sécurité.

---

## Introduction

Ce document détaille les modifications de sécurité appliquées aux dépendances de Pandoc pour permettre la compilation en WebAssembly. Ces patches ont été nécessaires car :

1. **Architecture 32-bit** : WASM utilise une architecture 32-bit, causant des incompatibilités avec du code optimisé pour 64-bit
2. **APIs système limitées** : WASI (WebAssembly System Interface) ne fournit pas toutes les APIs POSIX
3. **Pas de threading** : Le runtime WASM n'a pas de support threading natif
4. **Pas de réseau** : WASI Preview 1 a un support réseau très limité

**Important** : Ces patches n'ont pas été audités de manière exhaustive. Utilisez ce projet en connaissance de cause.

---

## Vue d'ensemble des modifications

| Package | Type de modification | Risque | Impact |
|---------|---------------------|--------|--------|
| basement | Conversions de types | Faible | Calculs numériques |
| memory | Désactivation fonctionnalités | Faible | Pas de memory-mapping |
| network | Stubs retournant erreurs | Moyen | Pas de réseau |
| cborg | Corrections 32-bit | Faible | Sérialisation CBOR |
| crypton | Désactivation threading | Faible | Crypto mono-thread |
| xml-conduit | Changement build-type | Aucun | Build uniquement |
| pandoc-cli | Suppression -threaded | Aucun | Runtime uniquement |

---

## Détail par package

### 1. basement-0.0.16

**Fichiers modifiés** :
- `cbits/foundation_system.h`
- `Basement/Numerical/Conversion.hs`
- `Basement/Numerical/Additive.hs`
- `Basement/Types/OffsetSize.hs`
- `Basement/From.hs`
- `Basement/PrimType.hs`
- `Basement/Bits.hs`

**Nature des modifications** :

```haskell
-- AVANT (GHC < 9.4)
import GHC.IntWord64

-- APRÈS (GHC >= 9.4)
import GHC.Prim (int64ToInt#, word64ToWord#, ...)
```

**Raison** : Le module `GHC.IntWord64` a été supprimé dans GHC 9.4+. Les primitives sont maintenant dans `GHC.Prim`.

**Conversions 32-bit** :

```haskell
-- Conversions explicites Word32# <-> Word# pour architecture 32-bit
word32ToWord# :: Word32# -> Word#
wordToWord32# :: Word# -> Word32#
```

**Implications de sécurité** :
- ✅ Pas d'impact sur la sécurité cryptographique
- ✅ Conversions de types standards
- ⚠️ Vérifier la correction des calculs sur grands nombres si critique

---

### 2. memory-0.18.0

**Fichiers modifiés** :
- `Data/Memory/Internal/CompatPrim64.hs`
- `Data/Memory/MemMap/Posix.hsc`
- `Data/ByteArray/Mapping.hs`
- `Data/Memory/PtrMethods.hs`
- `memory.cabal`

**Nature des modifications** :

1. **Désactivation de mmap** :
```haskell
-- Module MemMap.Posix désactivé sur wasm32
#if !defined(wasm32_HOST_ARCH)
-- code mmap original
#endif
```

2. **Corrections FFI** :
```haskell
-- Signatures FFI corrigées pour memcpy/memset
foreign import ccall unsafe "string.h memset"
    c_memset :: Ptr Word8 -> Word8 -> CSize -> IO (Ptr Word8)
```

**Implications de sécurité** :
- ✅ `mmap` n'est pas disponible en WASI de toute façon
- ✅ Les opérations mémoire utilisent l'allocateur standard
- ✅ Pas d'impact sur la sécurité des données en mémoire

---

### 3. network-3.2.8.0

**Fichiers modifiés** :
- `cbits/HsNet.c`
- `include/HsNet.h`

**Nature des modifications** :

Ajout de stubs pour les fonctions socket non fournies par WASI :

```c
/* cbits/HsNet.c - Stubs WASI */
#if defined(__wasi__) || defined(__wasm__)

int socket(int domain, int type, int protocol) {
    errno = ENOSYS;
    return -1;
}

int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen) {
    errno = ENOSYS;
    return -1;
}

int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen) {
    errno = ENOSYS;
    return -1;
}

// ... autres stubs similaires
#endif
```

**Fonctions stubées (retournent ENOSYS)** :
| Fonction | Comportement |
|----------|--------------|
| `socket()` | Retourne -1, errno=ENOSYS |
| `bind()` | Retourne -1, errno=ENOSYS |
| `listen()` | Retourne -1, errno=ENOSYS |
| `connect()` | Retourne -1, errno=ENOSYS |
| `setsockopt()` | Retourne 0 (succès factice) |
| `getsockopt()` | Retourne -1, errno=ENOPROTOOPT |
| `getpeername()` | Retourne -1, errno=ENOSYS |
| `getsockname()` | Retourne -1, errno=ENOSYS |
| `sendto()` | Retourne -1, errno=ENOSYS |
| `recvfrom()` | Retourne -1, errno=ENOSYS |

**Fonctions NON stubées** (fournies par WASI libc) :
- `accept()`, `send()`, `recv()`, `shutdown()`

**Implications de sécurité** :
- ✅ **Isolation réseau** : Aucune connexion réseau possible
- ✅ **Pas d'exfiltration de données** par réseau
- ⚠️ **Fonctionnalités cassées** : Tout code utilisant le réseau échouera
- ⚠️ `setsockopt()` retourne succès sans rien faire - code appelant peut avoir des attentes non respectées

---

### 4. cborg-0.2.10.0

**Fichiers modifiés** :
- `src/Codec/CBOR/Magic.hs`
- `src/Codec/CBOR/Decoding.hs`
- `src/Codec/CBOR/Read.hs`

**Nature des modifications** :

Corrections pour architecture 32-bit :

```haskell
-- Corrections de conversions Word64#/Int64# sur 32-bit
-- Suppression des imports GHC.IntWord64 dépréciés
-- Corrections de syntaxe dans isWord64Canonical, isInt64Canonical
```

**Implications de sécurité** :
- ✅ CBOR est utilisé pour la sérialisation de données
- ✅ Pas d'impact sur l'intégrité des données sérialisées
- ✅ Les tests de validation CBOR passent

---

### 5. crypton-1.0.5

**Fichiers modifiés** :
- `cbits/argon2/thread.h`
- `cbits/argon2/thread.c`

**Nature des modifications** :

```c
/* cbits/argon2/thread.h */
#if defined(__wasi__) || defined(__wasm__) || defined(__wasm32__)
#define ARGON2_NO_THREADS 1
#endif
```

**Raison** : WASI ne supporte pas `pthread_exit()`. Argon2 doit fonctionner en mode mono-thread.

**Implications de sécurité** :
- ✅ **Argon2 reste fonctionnel** en mode single-thread
- ⚠️ **Performance réduite** : Pas de parallélisation du hachage
- ✅ **Sécurité cryptographique préservée** : Argon2 mono-thread est toujours sécurisé
- ℹ️ Les paramètres de coût peuvent nécessiter ajustement pour compenser

**Note sur Argon2** : Argon2 est un algorithme de hachage de mots de passe. Le mode mono-thread est plus lent mais tout aussi sécurisé cryptographiquement.

---

### 6. xml-conduit-1.10.1.0

**Fichiers modifiés** :
- `xml-conduit.cabal`
- `Setup.hs`

**Nature des modifications** :

```cabal
-- AVANT
build-type: Custom
custom-setup
  setup-depends: base, Cabal, cabal-doctest

-- APRÈS  
build-type: Simple
```

**Raison** : Les packages avec `build-type: Custom` échouent en cross-compilation car le `Setup.hs` est compilé pour l'hôte, pas la cible WASM.

**Implications de sécurité** :
- ✅ **Aucun impact** : Changement de build uniquement
- ✅ Les doctests sont désactivés (tests uniquement)

---

### 7. pandoc-cli-3.8.3

**Fichiers modifiés** :
- `pandoc-cli.cabal`

**Nature des modifications** :

```cabal
-- AVANT
ghc-options: -threaded -rtsopts -with-rtsopts=-A8m

-- APRÈS
ghc-options: -rtsopts -with-rtsopts=-A8m
```

**Raison** : GHC WASM n'a pas de runtime threadé (`-lHSrts_thr` n'existe pas).

**Implications de sécurité** :
- ✅ **Aucun impact sur la sécurité**
- ℹ️ L'exécution est mono-thread (ce qui est la norme pour WASM)

---

## Implications globales de sécurité

### Isolation WASI

Le binaire `pandoc.wasm` s'exécute dans un environnement WASI isolé :

```
┌─────────────────────────────────────────┐
│              Host System                │
│  ┌───────────────────────────────────┐  │
│  │         WASI Sandbox              │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │      pandoc.wasm            │  │  │
│  │  │                             │  │  │
│  │  │  ✗ Pas de réseau           │  │  │
│  │  │  ✗ Pas de processus        │  │  │
│  │  │  ✓ Fichiers (--dir .)      │  │  │
│  │  │  ✓ stdin/stdout            │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

**Garanties de sécurité WASI** :
- ✅ Accès fichiers limité aux répertoires explicitement montés (`--dir`)
- ✅ Pas d'accès réseau
- ✅ Pas de création de processus
- ✅ Isolation mémoire du runtime WASM

### Points d'attention

| Aspect | Statut | Notes |
|--------|--------|-------|
| Exécution de code arbitraire | ✅ Protégé | Sandbox WASI |
| Accès fichiers | ⚠️ Contrôlé | Uniquement via `--dir` |
| Réseau | ✅ Bloqué | Stubs ENOSYS |
| Fuite mémoire | ℹ️ Possible | Comme tout programme |
| DoS (CPU) | ⚠️ Possible | Pas de limite de temps par défaut |

### Recommandations

1. **Limiter l'accès fichiers** : N'utilisez `--dir` que sur les répertoires nécessaires
2. **Timeout** : Utilisez `wasmtime run --wasm timeout=30s` pour limiter le temps d'exécution
3. **Mémoire** : Utilisez `--wasm max-memory=512MiB` pour limiter la mémoire
4. **Entrées** : Validez les fichiers d'entrée avant conversion

```bash
# Exemple d'exécution sécurisée
wasmtime run \
  --dir ./input:readonly \
  --dir ./output \
  --wasm timeout=60s \
  --wasm max-memory=1GiB \
  pandoc.wasm -o ./output/result.html ./input/document.md
```

---

## Audit et contributions

Ces patches n'ont pas fait l'objet d'un audit de sécurité formel. Si vous identifiez des problèmes de sécurité :

1. **Ne pas créer d'issue publique** pour les vulnérabilités
2. Contacter les mainteneurs en privé
3. Fournir une description détaillée et un PoC si possible

---

## Changelog des patches

| Date | Package | Modification |
|------|---------|--------------|
| 2026-01-28 | basement | Conversions 32-bit, suppression GHC.IntWord64 |
| 2026-01-28 | memory | Désactivation mmap, corrections FFI |
| 2026-01-28 | network | Stubs socket WASI |
| 2026-01-28 | cborg | Corrections 32-bit |
| 2026-01-28 | crypton | ARGON2_NO_THREADS |
| 2026-01-28 | xml-conduit | build-type: Simple |
| 2026-01-28 | pandoc-cli | Suppression -threaded |
