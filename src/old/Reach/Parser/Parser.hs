{-# LANGUAGE FlexibleContexts #-}

module Reach.Parser.Parser where

import Text.Parsec
import Text.Parsec.Language
import qualified Text.Parsec.Token as P
--
import Reach.Parser.ParseSyntax
import Reach.Parser.IndentParser
import Reach.Parser.LanguageDef

import Data.Char
--
--import Control.Monad

--myParse parser  input = runIndent "" $
--  runParserT parser () "" input
--
--

readProg :: String -> IO [Def]
readProg fp = do 
  s <- readFile fp 
  case parseI parseFile s of
    Left e -> print e >> return undefined
    Right a -> return a
    

parserI = parseI

def :: ParsecI Def
def = do
  (v : vs) <- many1 identifier
  reserved "="
  reserved "{"
  e <- expr
  reserved "}"
  return (Def v vs e)

parseFile :: ParsecI [Def]
parseFile =  whiteSpace >> many1 def

expr :: ParsecI Exp
expr =  caseExpr
    <|> lamExpr
    <|> appExpr    
 
innerExpr :: ParsecI Exp
innerExpr = parens expr 
         <|> varExpr
         <|> targetExpr

varExpr :: ParsecI Exp
varExpr = fmap Var identifier 

lamExpr :: ParsecI Exp
lamExpr = do
  reserved "\\"
  vs <- many1 identifier
  reserved "->"
  e <- expr 
  return (Lam vs e) 

targetExpr :: ParsecI Exp
targetExpr = reserved "Target" >> return Target

caseExpr :: ParsecI Exp
caseExpr = do
  reserved "case"
  subj <- expr
  reserved "of"
  alts <- block altPatt 
  return $ Case subj alts 

appExpr :: ParsecI Exp
appExpr = do 
  (e : es) <- many1 innerExpr 
  case e of
    (Var a) -> return $ if isUpper (head a)
                 then Con a es
                 else Ap e es
    Target -> return Target

pattern :: ParsecI Pattern
pattern =   parens pattern
       <|>  undefined

altPatt :: ParsecI Alt
altPatt = do
  p <- pattern
  reserved "->" 
  e <- expr 
  reserved ";"
  return (Alt p e)

