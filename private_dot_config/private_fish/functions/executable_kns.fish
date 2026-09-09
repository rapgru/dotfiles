function kns --description "Switch Kubernetes namespace with fzf"
    set -l ns (kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | fzf --prompt="k8s ns> " --height=40%)
    and kubectl config set-context --current --namespace=$ns
end
