
module Reach.Eval.Monad (
  module X,
  ReachT,
  ReachFail(..),
  MonadChoice(..)
  ) where

import Control.Monad.State as X
import Control.Monad.Except as X
import Control.Monad.Identity as X
import Control.Monad.List

import Reach.Eval.Env

data ReachFail
  = DataLimitFail
  | RecLimitFail
  | ConstraintFail deriving Show

type ReachT m = StateT Env (ExceptT ReachFail m)

class (Monad m) => MonadChoice m where
  memp :: m a
  infixr 4 <|>
  (<|>) :: m a -> m a -> m a


instance MonadChoice [] where
  memp = []
  l1 <|> l2 = l1 ++ l2

instance MonadChoice m => MonadChoice (ExceptT e m) where
  memp = lift memp
  ExceptT l1 <|> ExceptT l2 = ExceptT $ l1 <|> l2 

instance MonadChoice m => MonadChoice (StateT e m) where
  memp = lift memp
  StateT s1 <|> StateT s2 = StateT $ \e -> s1 e <|> s2 e
    

class Monad m => MonadFork m i t | m -> i, m -> t where
  fork :: i -> [(t , m a)] -> m a
