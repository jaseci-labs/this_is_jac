"""Regression: the "Browse the source" feature must enumerate files even when
git is unavailable. In a `--scale` deploy the pod ships the source tree but no
`.git` dir or `git` binary, so the git-only path returned nothing and the
source viewer was empty in-cluster while working locally. The filesystem-walk
fallback (source_index._raw_files) restores parity.
"""

import os;
import tempfile;
import from source_index { list_files, get_file }


test "source listing falls back to a filesystem walk when git is unavailable" {
    d = tempfile.mkdtemp();
    with open(os.path.join(d, "main.jac"), "w") as fh {
        fh.write("with entry { print(\"hi\"); }");
    }
    # node_modules must be pruned by the walk just as git's --exclude-standard
    # would drop it.
    os.makedirs(os.path.join(d, "node_modules", "pkg"), exist_ok=True);
    with open(os.path.join(d, "node_modules", "pkg", "junk.js"), "w") as fh {
        fh.write("module.exports = {};");
    }

    # `d` is a bare temp dir: not a git repo (and in a pod, no git binary at
    # all), so the git path yields nothing and the walk must take over.
    files = list_files(base_dir=d);
    names = [x["name"] for x in files];

    assert "main.jac" in names ,
        "source listing must enumerate files via the filesystem walk when git "
        "is unavailable (deploy-pod parity)";
    assert "junk.js" not in names ,
        "node_modules must be pruned by the walk";

    one = get_file("main.jac", base_dir=d);
    assert one["error"] == "" and "hi" in one["raw"] ,
        "get_file must read a walked file in a git-less tree";
}
