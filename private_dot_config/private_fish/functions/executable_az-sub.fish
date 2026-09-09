function az-sub
  az account set --subscription (az account list --query '[].name' -o tsv | fzf)
end
