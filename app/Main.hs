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
import Data.Proxy
import GHC.Generics
import Network.HTTP.Client (newManager, defaultManagerSettings)
import Servant.API
import Servant.Client

type MyPut = Verbs.Verb PUT 201

type ReqAPI = 
      "storage" :> Capture "my-file" FileName :> (Get '[JSON] Value
       :<|> ReqBody '[JSON] Value :> MyPut '[JSON] ()
       :<|> DeleteNoContent '[JSON] ())
       
type ResAPI = 
      "storage" :> Capture "my-file" FileName :> Get '[JSON] Value
       :<|> "storage" :> Capture "my-file" FileName :> ReqBody '[JSON] Value :> MyPut '[JSON] ()
       :<|> "storage" :> Capture "my-file" FileName :> DeleteNoContent '[JSON] ()

type FileName = String

reqApi :: Proxy ReqAPI
reqApi = Proxy

resApi :: Proxy ResAPI
resApi = Proxy

getFromServer :: FileName -> ClientM Value
putFromServer :: FileName -> Value -> ClientM ()
delFromServer :: FileName -> ClientM ()
getFromServer :<|> putFromServer :<|> delFromServer = client resApi

callServer :: Show a => ClientM a -> IO (Either ClientError a) 
callServer task = do
    res <- call 8081
    print res
    case res of
      Left _ -> call 8080 >>= pure
      resp -> pure resp
    where
      call port = do
        manager' <- newManager defaultManagerSettings
        runClientM task (mkClientEnv manager' (BaseUrl Http "localhost" port ""))


server :: Server ReqAPI 
server file = get file :<|> put file :<|> del file
  where
    get :: FileName -> Handler Value
    get file = do
      res <- liftIO $ callServer (getFromServer file)
      either (throwError . const err404) pure res

    put :: FileName -> Value -> Handler ()
    put file req = do
      res <- liftIO $ callServer (putFromServer file req)
      either (throwError . const err404) pure res

    del :: FileName -> Handler ()
    del path = do
      res <- liftIO $ callServer (delFromServer path)
      either (throwError . const err404) pure res

app :: Application
app = serve reqApi server

main :: IO ()
main = run 8082 app
