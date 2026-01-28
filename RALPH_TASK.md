Rôle : Expert en compilation Haskell et WebAssembly (WASI).

Objectif : Compiler la dernière version stable officielle de Pandoc (pas le fork) en un module wasm32-wasi autonome et valider son fonctionnement avec wasmtime.

Environnement technique :

    Compilateur : Utilise ghc-wasm-meta avec la version GHC 9.12 (ou plus récente).

    Outils : wasm32-wasi-cabal et wasm32-wasi-ghc doivent être dans ton PATH.

    Runtime : wasmtime pour l'exécution et les tests.

Instructions de compilation :

    Phase 1 (Priorité Haute) : Tente de compiler la version 3.8.3 (ou la plus récente disponible sur Hackage/GitHub) de Pandoc sans modifications majeures. L'objectif est de préserver le maximum de fonctionnalités (Lua, filtres, etc.).

    Phase 2 (Stratégie de repli) : Si la compilation échoue à cause de dépendances incompatibles avec WASI (ex: network, sockets, setjmp/longjmp), applique progressivement les ajustements suivants comme "indices" :

        Désactiver le support Lua (car il nécessite souvent la gestion des exceptions WASM ou setjmp).

        Désactiver les fonctionnalités HTTP/Serveur (les sockets ne sont pas encore totalement supportés en WASI p1).

        Utiliser des flags Cabal pour exclure les dépendances problématiques.

Validation (Critères de succès) : Une fois le binaire pandoc.wasm généré, tu dois prouver son bon fonctionnement en convertissant trois fichiers Markdown (small.md, medium.md, large.md) dans les formats suivants :

    PPTX (PowerPoint).

    PDF (Note : si l'absence d'un moteur LaTeX externe pose problème dans l'environnement WASI, privilégie l'export via le moteur interne Typst ou concentre-toi sur le format PPTX qui est géré nativement par Pandoc).

Commande de test attendue : wasmtime run --dir . pandoc.wasm -- -f markdown -t pptx -o output.pptx input.md
