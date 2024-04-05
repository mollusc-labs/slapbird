((cperl-mode
  (eval .
        (setq flycheck-perl-include-path
              (add-to-list
               'flycheck-perl-include-path
               (concat (projectile-project-root) "lib"))))))
