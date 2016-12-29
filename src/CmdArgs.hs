
{-# LANGUAGE DeriveDataTypeable #-}
{-# OPTIONS_GHC -fno-cse #-}
{-# OPTIONS_GHC -fno-warn-missing-fields #-}

module CmdArgs where

import Data.Version            (showVersion)
import Paths_hup               (version)
import System.Console.CmdArgs hiding(cmdArgs)  
import System.Environment      (getArgs, withArgs)

import qualified DefaultServerUrl
import CmdArgs.PatchHelp (cmdArgs)

defaultServer = DefaultServerUrl.defaultServerUrl 

-- | Actions the program can perform
data HupCommands = 
    Docbuild  { verbose  :: Bool
                , executables :: Bool
                , tests :: Bool
                , internal :: Bool
                ,haddockArgs :: String 
                ,quick :: Bool }
  | Docboth   { verbose  :: Bool 
              , executables :: Bool
              , tests :: Bool
              , internal :: Bool
              , haddockArgs :: String 
              , quick :: Bool 
              , server   :: String 
              , candidate :: Bool
              , user     :: Maybe String 
              , password :: Maybe String  }
              
  | Packup    { verbose  :: Bool 
              , server   :: String
              , candidate :: Bool
              , user     :: Maybe String 
              , password :: Maybe String
              , file     :: String }
  | Docup     { verbose  :: Bool 
              , server   :: String 
              , candidate :: Bool
              , user     :: Maybe String 
              , password :: Maybe String
              , file     :: String }
      deriving (Show, Eq, Data, Typeable, Ord)

isUpload Docbuild {} = Nothing
isUpload x           = Just x 

-- Helpers for specifying metavariables etc. for 
-- arguments.

{-# INLINE serverArg #-}
serverArg x = x &= typ  "URL"

{-# INLINE userArg #-}
userArg   x = x &= typ  "USER"

{-# INLINE passwdArg #-}
passwdArg x = x &= typ  "PASSWORD"

{-# INLINE fileArg #-}
fileArg x = x &= typ "FILE" 

{-# INLINE verbArgs #-}
verbArgs x = x &= help "be verbose" 

-- commands that can be run

packup = 
  Packup
    { verbose    = verbArgs   def
      ,server    = serverArg  defaultServer  
      ,candidate =            def  
      ,file      = fileArg    def  &= argPos 0  
      ,user      = userArg    Nothing  
      ,password  = passwdArg  Nothing }
       &= help     (unwords   ["Upload FILE as a package (or"
                                              ,"candidate package)."])

docbuild = 
  Docbuild
    { verbose     = verbArgs  def
     ,executables =           def &= help "Run haddock for Executables targets"
     ,tests       =           def &= help "Run haddock for Test Suite targets"
     ,internal    =           def &= help (unwords ["Run haddock for internal"
                                           ,"modules and include all symbols"])
     ,haddockArgs =           def &= help "extra args to pass to haddock"
                                  &= explicit
                                  &= name "haddock-arguments"
                                  &= typ  "ARGS"   
     ,quick       =           def &= help (unwords ["quick build - don't build"
                                          ,"docco for dependencies (links may"
                                          ,"be broken)"])
     }
      &= help     "Build documentation for a package."

docup =
  Docup 
    { server = serverArg  defaultServer 
     ,file   = fileArg    def &= argPos 0 
     }
     &= help "Upload FILE as documentation."

docboth = 
  Docboth 
    {}
    &= help "Build and upload documentation for a package."

-- Process command-line arguments
processArgs = do
   args <- getArgs
    -- If the user did not specify any arguments, pretend as "--help" was given
   (if null args then withArgs ["--help"] else id) proc

  where 
  proc :: IO HupCommands
  proc = cmdArgs $ -- commands that can be run, i.e. "modes"
           modes [packup  
                 ,docbuild -- &= groupname "A" 
                 ,docup    -- &= groupname "B"
                 ,docboth ]  -- &= groupname "C"] 
                  &= help progHelp
                  &= program "hup"
                  &= summary ("hup v" ++ showVersion version)
                  &= helpArg [explicit, name "h", name "help"]

  progHelp = unwords 
     ["Build and/or upload packages or documentation to a hackage server."
     ,"A server url should be of the format PROTOCOL://SERVER[:PORT]/,"
     ,"and defaults to", defaultServer, "if not specified.\n"
     ,"\nA password can also be given in the PASSWORD environment"
     ,"variable instead of on the command line.\n", "\n'hup --help=all'"
     ,"will give help for all commands." ]

