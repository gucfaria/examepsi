#!/bin/bash
# Publica o Gerador de Exame Psíquico no GitHub (gucfaria/examepsi) + GitHub Pages.
# Uso: duplo clique. Opcional no Terminal: ./publicar.command "mensagem do commit"
cd "$(dirname "$0")" || exit 1
exec > >(tee publicar.log) 2>&1
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
REPO="gucfaria/examepsi"
echo "== $(date) =="
echo "git: $(command -v git)  gh: $(command -v gh || echo ausente)"

# 1) O arquivo de trabalho é o "Gerador de Exame Psíquico.html"; o Pages serve o index.html.
#    (glob em vez do nome literal: evita problema de acento NFC/NFD)
for f in *Exame*.html; do [ -f "$f" ] && cp "$f" index.html && echo "Copiado: $f -> index.html"; done
[ -f index.html ] || { echo "ERRO: index.html não encontrado"; exit 1; }

# 2) Repositório local (só na primeira vez).
[ -d .git ] || git init -b main
git config user.name  >/dev/null || git config --global user.name  "Gustavo Coutinho de Faria"
git config user.email >/dev/null || git config --global user.email "gucfaria@gmail.com"
printf 'publicar.log\n.DS_Store\n' > .gitignore
git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$REPO.git"

# 3) Commit.
git add index.html .gitignore publicar.command
git commit -m "${1:-Atualização} ($(date +%Y-%m-%d))" || echo "(nada novo para commitar)"

# 4) Se o remoto já tem commits (README/licença criados no site), incorpora antes do push.
if git ls-remote --exit-code --heads origin main >/dev/null 2>&1; then
  git pull --no-rebase --no-edit --allow-unrelated-histories origin main || echo "(pull falhou — veja acima)"
fi

# 5) Push (HTTPS; se falhar, tenta SSH só nesta vez, sem trocar o remote).
if git push -u origin main; then
  echo "PUSH_OK"
else
  echo "HTTPS falhou; tentando SSH..."
  GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new" git push "git@github.com:$REPO.git" main && echo "PUSH_OK (ssh)" || { echo "PUSH_FALHOU"; ls ~/.ssh 2>/dev/null | sed 's/^/  ssh: /'; }
fi

# 6) Ativa o GitHub Pages (main / raiz) se o gh estiver logado.
if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
  if gh api "repos/$REPO/pages" >/dev/null 2>&1; then
    echo "Pages já ativo."
  else
    gh api -X POST "repos/$REPO/pages" -f "source[branch]=main" -f "source[path]=/" >/dev/null \
      && echo "Pages ativado (1–2 min na primeira vez)." \
      || echo "Não consegui ativar o Pages pelo gh — ative em Settings → Pages → main / (root)."
  fi
else
  echo "gh ausente ou sem login — se ainda não ativou: Settings → Pages → main / (root)."
fi

echo "Página: https://gucfaria.github.io/examepsi/"
echo "== fim =="
