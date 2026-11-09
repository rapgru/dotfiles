function az-sub
  az account set --subscription (az account list --query '[].name' -o tsv | fzf --prompt="az sub> " --height=40%)
end
