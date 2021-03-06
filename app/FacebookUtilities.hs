{-# LANGUAGE OverloadedStrings, FlexibleContexts, GADTs #-}
module FacebookUtilities where

import qualified Facebook as FB
import Control.Monad.IO.Class  (liftIO)
import qualified Data.Text as T
import Happstack.Server
import Network.HTTP.Conduit (withManager, parseUrl, httpLbs)
import Control.Monad.Trans.Resource
import qualified Data.Conduit.List as CL
import Data.Conduit
import Database.Persist
import Export.ImageConversion
import Response.Graph
import Database.Tables
import qualified Data.ByteString.Char8 as BS
import Database.Persist.Sqlite
import Network.HTTP.Client.MultipartFormData
import Network (withSocketsDo)

courseographyUrl :: T.Text
courseographyUrl = "http://localhost:8000"

testUrl :: FB.RedirectUrl
testUrl = T.append courseographyUrl "/test"

testPostUrl :: FB.RedirectUrl
testPostUrl = T.append courseographyUrl "/test-post"

postFB :: T.Text
postFB = "post-fb"

-- | The name of the \'fbdatabase\' that isn't actually used anymore.
fbdatabasePath :: T.Text
fbdatabasePath = "fdatabase1.sqlite3"

appId :: T.Text
appId = "432140593606098"

-- In order to access information as the Courseography application, the secret needs
-- to be declared in the third string below that has the place holder 'INSERT_SECRET'.
-- The secret should NEVER be committed to GitHub.
-- The secret can be found here: https://developers.facebook.com/apps/432140593606098/dashboard/
-- Should the secret be committed to GitHub, it needs to be reset immediately. If you find
-- yourself in this pickle, please contact someone who can do this.
appSecret :: T.Text
appSecret = "INSERT_SECRET"

credentials :: FB.Credentials
credentials = FB.Credentials courseographyUrl appId appSecret

perms :: [FB.Permission]
perms = ["publish_actions"]

postPhoto :: FB.UserAccessToken -> FB.UserId -> IO Response
postPhoto (FB.UserAccessToken _ b _) _ = withSocketsDo $ withManager $ \m -> do
    fbpost <- parseUrl $ "https://graph.facebook.com/v2.2/me/photos?access_token=" ++ T.unpack b
    flip httpLbs m =<<
        formDataBody [partBS "message" "Test Message",
                      partFileSource "graph" "INSERT_ID-graph.png"]
                      fbpost
    return $ toResponse postFB

-- | Constructs the Facebook authorization URL. This method does not actually
-- interact with Facebook.
retrieveAuthURL :: T.Text -> IO T.Text
retrieveAuthURL url =
    performFBAction $ FB.getUserAccessTokenStep1 url perms


-- | Retrieves the user's email.
retrieveFBData :: BS.ByteString -> IO Response
retrieveFBData code =
    performFBAction $ do
        token <- getToken testUrl code
        user <- FB.getUser "me" [] (Just token)
        liftIO $ insertIdIntoDb (FB.userId user)
        return $ toResponse (FB.userEmail user)

-- | Performs a Facebook action.
performFBAction :: FB.FacebookT FB.Auth (ResourceT IO) a -> IO a
performFBAction action = withManager $ \manager -> FB.runFacebookT credentials manager action

-- | Posts a message to the user's Facebook feed, with the code 'code'. GraphResponse
-- is then sent back to the user.
postToFacebook :: String -> ServerPart Response
postToFacebook code = (liftIO $ performPost (BS.pack code)) >> graphResponse

-- | Performs the posting to facebook.
performPost :: BS.ByteString -> IO Response
performPost code =
    performFBAction $ do
        token <- getToken testPostUrl code
        user <- FB.getUser "me" [] (Just token)
        let id_ = FB.userId user
        liftIO $ createImageFile "" "INSERT_ID-graph.png"
        liftIO $ postPhoto token id_
        liftIO $ removeImage "INSERT_ID-graph.png"
        return $ toResponse postFB

-- | Gets a user access token.
getToken :: (MonadResource m, MonadBaseControl IO m) => FB.RedirectUrl -> BS.ByteString -> FB.FacebookT FB.Auth m FB.UserAccessToken
getToken url code = FB.getUserAccessTokenStep2 url [("code", code)]

-- | Gets a user's Facebook email.
getEmail :: String -> ServerPart Response
getEmail code = liftIO $ retrieveFBData (BS.pack code)

-- | Inserts a string into the database along with the current user's Facebook ID.
-- Note: Meant as an experimental function for inserting user information into the database.
--       This function is not used.
insertIdIntoDb :: FB.Id -> IO ()
insertIdIntoDb id_ =
    runSqlite fbdatabasePath $ do
        runMigration migrateAll
        insert_ $ FacebookTest (show id_) "Test String"
        liftIO $ print "Inserted..."
        let sql = "SELECT * FROM facebook_test"
        rawQuery sql [] $$ CL.mapM_ (liftIO . print)
