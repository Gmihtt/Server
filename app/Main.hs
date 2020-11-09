{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeOperators #-}

module Main where

import Control.Monad.Except
import qualified Servant.API.Verbs as Verbs
import Data.Aeson ( decode, encode, Value)
import qualified Data.ByteString.Lazy as ByteString
import Data.Maybe (fromMaybe)
import Network.Wai.Handler.Warp (run)
import Servant
import System.Directory ( doesFileExist, removePathForcibly )
import Prelude

type MyPut = Verbs.Verb PUT 201

type API = 
      "storage" :> Capture "my-file" FileName :> (Get '[JSON] Value
       :<|> ReqBody '[JSON] Value :> MyPut '[JSON] ()
       :<|> DeleteNoContent '[JSON] ())

type FileName = String

api :: Proxy API
api = Proxy

server :: Server API 
server file = get file :<|> put file :<|> del file
  where
    get :: FileName -> Handler Value
    get file = do
      exists <- liftIO (doesFileExist file)
      if exists
        then do
         json <- liftIO (ByteString.readFile file)
         let str = decode json :: Maybe Value
         return . fromMaybe "" $ str
        else throwError err404

    put :: FileName -> Value -> Handler ()
    put file req = liftIO (ByteString.writeFile file $ encode req)

    del :: FileName -> Handler ()
    del path = liftIO $ removePathForcibly path

app :: Application
app = serve api server

main :: IO ()
main = run 8080 app
