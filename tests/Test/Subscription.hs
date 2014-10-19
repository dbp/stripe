{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE OverloadedStrings #-}
module Test.Subscription where

import           Data.Either
import           Test.Config        (getConfig)
import           Test.Hspec
import           Control.Monad
import           Control.Applicative
import qualified Data.Text as T
import           System.Random

import           Web.Stripe
import           Web.Stripe.Subscription
import           Web.Stripe.Customer
import           Web.Stripe.Plan

makePlanId :: IO PlanId
makePlanId = PlanId . T.pack <$> replicateM 10 (randomRIO ('a', 'z'))

subscriptionTests :: Spec
subscriptionTests = do
  describe "Subscription tests" $ do
    it "Succesfully creates a Subscription" $ do
      config <- getConfig
      planid <- makePlanId
      result <- stripe config $ do
        Customer { customerId = cid } <- createEmptyCustomer
        void $ createPlan planid
                        0 -- free plan
                        (Currency "usd")
                        Month
                        "sample plan"
                        []
        sub <- createSubscription cid planid []
        void $ deletePlan planid
        void $ deleteCustomer cid
        return sub
      result `shouldSatisfy` isRight
    it "Succesfully retrieves a Subscription" $ do
      config <- getConfig
      planid <- makePlanId
      result <- stripe config $ do
        Customer { customerId = cid } <- createEmptyCustomer
        void $ createPlan planid
                        0 -- free plan
                        (Currency "usd")
                        Month
                        "sample plan"
                        []
        Subscription { subscriptionId = sid } <- createSubscription cid planid []
        sub <- getSubscription cid sid
        void $ deletePlan planid
        void $ deleteCustomer cid
        return sub
      result `shouldSatisfy` isRight
    it "Succesfully retrieves a Subscription expanded" $ do
      config <- getConfig
      planid <- makePlanId
      result <- stripe config $ do
        Customer { customerId = cid } <- createEmptyCustomer
        void $ createPlan planid
                        0 -- free plan
                        (Currency "usd")
                        Month
                        "sample plan"
                        []
        Subscription { subscriptionId = sid } <- createSubscription cid planid []
        sub <- getSubscriptionExpandable cid sid ["customer"]
        void $ deletePlan planid
        void $ deleteCustomer cid
        return sub
      result `shouldSatisfy` isRight
    it "Succesfully retrieves a Customer's Subscriptions expanded" $ do
      config <- getConfig
      planid <- makePlanId
      result <- stripe config $ do
        Customer { customerId = cid } <- createEmptyCustomer
        void $ createPlan planid
                        0 -- free plan
                        (Currency "usd")
                        Month
                        "sample plan"
                        []
        void $ createSubscription cid planid []
        sub <- getSubscriptionsExpandable cid Nothing Nothing Nothing ["data.customer"]
        void $ deletePlan planid
        void $ deleteCustomer cid
        return sub
      result `shouldSatisfy` isRight
    it "Succesfully retrieves a Customer's Subscriptions" $ do
      config <- getConfig
      planid <- makePlanId
      result <- stripe config $ do
        Customer { customerId = cid } <- createEmptyCustomer
        void $ createPlan planid
                        0 -- free plan
                        (Currency "usd")
                        Month
                        "sample plan"
                        []
        void $ createSubscription cid planid []
        sub <- getSubscriptions cid Nothing Nothing Nothing 
        void $ deletePlan planid
        void $ deleteCustomer cid
        return sub
      result `shouldSatisfy` isRight
    it "Succesfully cancels a Customer's Subscription" $ do
      config <- getConfig
      planid <- makePlanId
      result <- stripe config $ do
        Customer { customerId = cid } <- createEmptyCustomer
        void $ createPlan planid
                        0 -- free plan
                        (Currency "usd")
                        Month
                        "sample plan"
                        []
        Subscription { subscriptionId = sid } <- createSubscription cid planid []
        sub <- cancelSubscription cid sid False
        void $ deletePlan planid
        void $ deleteCustomer cid
        return sub
      result `shouldSatisfy` isRight
      let Right Subscription {..} = result
      subscriptionStatus `shouldBe` Canceled