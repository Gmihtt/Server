{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module Endpoints (app) where

import qualified Servant.API.Verbs as Verbs
import Data.Aeson (Value)
import Network.Wai
import Servant
import LogRequest ( writeLog )
import FileLogic (get, put, del)

type MyPut = Verbs.Verb PUT 201

type API = 
      "storage" :> Capture "my-file" FilePath :> (Get '[JSON] Value
       :<|> ReqBody '[JSON] Value :> MyPut '[JSON] ()
       :<|> DeleteNoContent '[JSON] ())

api :: Proxy API
api = Proxy

server :: Server API 
server file = get file :<|> put file :<|> del file

app :: Application
app req respond = do
  writeLog req
  serve api server req respond
