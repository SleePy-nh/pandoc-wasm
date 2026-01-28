{-# LANGUAGE NoRebindableSyntax #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
{-# OPTIONS_GHC -w #-}
module PackageInfo_basement (
    name,
    version,
    synopsis,
    copyright,
    homepage,
  ) where

import Data.Version (Version(..))
import Prelude

name :: String
name = "basement"
version :: Version
version = Version [0,0,16] []

synopsis :: String
synopsis = "Foundation scrap box of array & string"
copyright :: String
copyright = "2015-2017 Vincent Hanquez <vincent@snarc.org>\n, 2017-2018 Foundation Maintainers"
homepage :: String
homepage = "https://github.com/haskell-foundation/foundation#readme"
