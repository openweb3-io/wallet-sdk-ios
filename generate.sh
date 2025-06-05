#!/usr/bin/env bash

swift run swift-openapi-generator generate \
  --config Sources/wallet-sdk-ios/openapi-generator-config.yaml \
  --output-directory Sources/wallet-sdk-ios/Generated \
  Sources/wallet-sdk-ios/openapi.yaml
