function kctx --description "Switch Kubernetes context with fzf"
    set -l ctx (kubectl config get-contexts -o name | fzf --prompt="k8s ctx> " --height=40%)
    and kubectl config use-context $ctx
end
