{-# OPTIONS_GHC -fglasgow-exts #-} -- For deriving Data/Typeable
{-# LANGUAGE FlexibleContexts, FlexibleInstances, MultiParamTypeClasses, TypeSynonymInstances #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  XMonadContrib.Maximize
-- Copyright   :  (c) 2007 James Webb
-- License     :  BSD3-style (see LICENSE)
--
-- Maintainer  :  xmonad#jwebb,sygneca,com
-- Stability   :  unstable
-- Portability :  unportable
--
-- Temporarily yanks the focused window out of the layout to mostly fill
-- the screen.
--
-----------------------------------------------------------------------------

module XMonadContrib.Maximize (
        -- * Usage
        -- $usage
        maximize,
        maximizeRestore
    ) where

import Graphics.X11.Xlib
import XMonad
import XMonadContrib.LayoutModifier
import Data.List ( partition )

-- $usage
-- You can use this module with the following in your Config.hs file:
--
-- > import XMonadContrib.Maximize
--
-- > layouts = ...
-- >                  , Layout $ maximize $ tiled ...
-- >                  ...
--
-- > keys = ...
-- >        , ((modMask, xK_backslash), withFocused (sendMessage . maximizeRestore))
-- >        ...

-- %import XMonadContrib.Maximize
-- %layout , Layout $ maximize $ tiled

data Maximize a = Maximize (Maybe Window) deriving ( Read, Show )
maximize :: LayoutClass l Window => l Window -> ModifiedLayout Maximize l Window
maximize = ModifiedLayout $ Maximize Nothing

data MaximizeRestore = MaximizeRestore Window deriving ( Typeable, Eq )
instance Message MaximizeRestore
maximizeRestore :: Window -> MaximizeRestore
maximizeRestore = MaximizeRestore

instance LayoutModifier Maximize Window where
    modifierDescription (Maximize _) = "Maximize"
    redoLayout (Maximize mw) rect _ wrs = case mw of
        Just win ->
                return (maxed ++ rest, Nothing)
            where
                maxed = map (\(w, _) -> (w, maxRect)) toMax
                (toMax, rest) = partition (\(w, _) -> w == win) wrs
                maxRect = Rectangle (rect_x rect + 50) (rect_y rect + 50)
                    (rect_width rect - 100) (rect_height rect - 100)
        Nothing -> return (wrs, Nothing)
    handleMess (Maximize mw) m = case fromMessage m of
        Just (MaximizeRestore w) -> case mw of
            Just _ -> return $ Just $ Maximize Nothing
            Nothing -> return $ Just $ Maximize $ Just w
        _ -> return Nothing

-- vim: sw=4:et