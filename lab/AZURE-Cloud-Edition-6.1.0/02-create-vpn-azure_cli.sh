#!/bin/bash
# Uncomment set command below for code debuging bash
#set -x

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PREFIX="$(head -20 config.yml | grep PREFIX | awk '{ print $2}')"
PREFIXVPN="$PREFIX-vpn"

VNET_CIDR_BLOCK="$(cat config.yml | grep VNET_CIDR_BLOCK | awk '{ print $2}')"
SUBNET1_CIDR_BLOCK="$(cat config.yml | grep SUBNET1_CIDR_BLOCK | awk '{ print $2}')"
SUBNET2_CIDR_BLOCK="$(cat config.yml | grep SUBNET2_CIDR_BLOCK | awk '{ print $2}')"
SUBNET3_CIDR_BLOCK="$(cat config.yml | grep SUBNET3_CIDR_BLOCK | awk '{ print $2}')"
CUSTOMER_GATEWAY_IP="$(cat config.yml | grep CUSTOMER_GATEWAY_IP | awk '{ print $2}')"
EXT_NETWORK_UDF_VPN="$(cat config.yml | grep EXT_NETWORK_UDF_VPN | awk '{ print $2}')"
DEFAULT_REGION="$(cat config.yml | grep DEFAULT_REGION | awk '{ print $2}')"
LOCAL_GATEWAY="$(cat config.yml | grep LOCAL_GATEWAY | awk '{ print $2}')"

# https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-site-to-site-resource-manager-cli

echo -e "\n${GREEN}Create a resource group${NC}"
az group create --name $PREFIX --location eastus

echo -e "\n${GREEN}Create a virtual network and subnet 1${NC}"
az network vnet create \
  -n VNet1 \
  -g $PREFIX \
  -l $DEFAULT_REGION \
  --address-prefix $VNET_CIDR_BLOCK \
  --subnet-name Subnet1 \
  --subnet-prefix $SUBNET1_CIDR_BLOCK

echo -e "\n${GREEN}Create subnet 2${NC}"
az network vnet subnet create \
  --vnet-name VNet1 \
  -n Subnet2 \
  -g $PREFIX \
  --address-prefix $SUBNET2_CIDR_BLOCK

echo -e "\n${GREEN}Add a gateway subnet${NC}"
az network vnet subnet create \
  --vnet-name VNet1 \
  -n GatewaySubnet \
  -g $PREFIX \
  --address-prefix $SUBNET3_CIDR_BLOCK

echo -e "\n${GREEN}Create the local network gateway${NC}"
az network local-gateway create \
   --gateway-ip-address $CUSTOMER_GATEWAY_IP --name $LOCAL_GATEWAY --resource-group $PREFIX \
   --local-address-prefixes $EXT_NETWORK_UDF_VPN

# To modify the local network gateway 'gatewayIpAddress'
# az network local-gateway update --gateway-ip-address 23.99.222.170 --name Site2 --resource-group TestRG1

echo -e "\n${GREEN}View the subnets${NC}"
az network vnet subnet list -g $PREFIX --vnet-name VNet1 --output table

echo -e "\n${GREEN}Request a public IP address${NC}"
az network public-ip create \
  -n VNet1GWIP \
  -g $PREFIX \
  --allocation-method Dynamic 

echo -e "\n${GREEN}Create the VPN gateway${NC}"
az network vnet-gateway create \
  -n VNet1GW \
  -l eastus \
  --public-ip-address VNet1GWIP \
  -g $PREFIX \
  --vnet VNet1 \
  --gateway-type Vpn \
  --sku VpnGw1 \
  --vpn-type RouteBased \
  --no-wait

echo -e "\n${GREEN}View the VPN gateway${NC}"
az network vnet-gateway show \
  -n VNet1GW \
  -g $PREFIX \
  --output table

echo -e "\n${GREEN}View the public IP address${NC}"
az network public-ip show \
  --name VNet1GWIP \
  --resource-group $PREFIX \
  --output table

echo -e "\n${GREEN}Create the VPN connection${NC}"
az network vpn-connection create --name $PREFIXVPN --resource-group $PREFIX --vnet-gateway1 VNet1GW -l $DEFAULT_REGION --shared-key abc123 --local-gateway2 $LOCAL_GATEWAY --enable-bgp

echo -e "\n${GREEN}Verify the VPN connection${NC}"
az network vpn-connection show --name $PREFIXVPN --resource-group $PREFIX --output table

exit 0
