{-# LINE 1 "Basement/Terminal/Size.hsc" #-}
{-# LANGUAGE CApiFFI #-}
module Basement.Terminal.Size 
    ( getDimensions
    ) where
        
import           Foreign
import           Foreign.C
import           Basement.Compat.Base
import           Basement.Types.OffsetSize
import           Basement.Numerical.Subtractive
import           Basement.Numerical.Additive
import           Prelude (fromIntegral)









-- defined FOUNDATION_SYSTEM_WINDOWS




-- defined FOUNDATION_SYSTEM_WINDOWS

-- | Return the size of the current terminal
--
-- If the system is not supported or that querying the system result in an error
-- then a default size of (80, 24) will be given back.
getDimensions :: IO (CountOf Char, CountOf Char)
getDimensions =

    pure defaultSize

  where
    defaultSize = (80, 24)
