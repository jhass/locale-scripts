#!/usr/bin/python
import httplib2
import os
import re

master = "en"
common_keys = {"ar", "cs", "cy", "de", "es", "fi", "fr", "he", "id", "it", "lt",
               "nb", "nl", "pl", "ro", "ru", "sv", "tr", "pt-BR", "pt-PT", "el", 
               "da", "sk", "eo", "mk", "hu", "es-CL",  "en_shaw", "br", "bg", "ga",
               "is", "eu", "zh-CN", "zh-TW", "pa", "ko", "ja", "es-AR", "en_pirate",
               "ur-PK", "nn", "uk", "sq", "en_1337", "vi", "de_formal", "sl", "fil",
               "ms", "te", "ka", "ml"
               }
files = {("diaspora/", "$lang.yml"): [],
         ("devise/", "devise.$lang.yml"): [],
         ("javascript/", "javascript.$lang.yml"): []
        }
root = "config/locales/"
api_key = "77706006961"
header = """#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.


"""
validline = re.compile(r"^[\s\w]+.*$")
fix_unquoted = re.compile(r'^(\s+\w+?):\s((?!")[\w\s\b]+(?!"))$')
def replace_with_quoted(match):
    return match.group(1)+': "'+match.group(2)+'"'

updated_keys = []

if __name__ == "__main__":
    actions = sum([len(c) for c in files.values()])
    actions += (len(common_keys)*len(files.keys()))*2
    done = 1
    fetcher = httplib2.Http()
    errors = []
    for fileparams, codes in files.items():
        directory, filename = fileparams
        codes.extend(common_keys)
        codes = set(codes)
        baseurl = "http://99translations.com/download/"+api_key+"/"+filename.replace("$lang", master)+"/"
        basepath = os.path.join(root, directory)
        for lang in codes:
            url = baseurl+lang
            path = os.path.join(basepath, filename.replace("$lang", lang))
            try:
                print("("+str(done)+"/"+str(actions)+")", "Downloading", url)
                resp, content = fetcher.request(url)
                assert resp.status == 200, (filename.replace("$lang", lang), resp.status)
                done += 1
                with open(path, "w", encoding='utf-8') as langfile:
                    print("("+str(done)+"/"+str(actions)+")", "Updating", path)
                    langfile.write(header)
                    for line in content.splitlines():
                        match = validline.match(line.decode('utf-8'))
                        if not match == None:
                            line = fix_unquoted.sub(replace_with_quoted, line.decode('utf-8'))
                            langfile.write(line.rstrip()+"\n")
                done += 1
            except AssertionError as e:
                if e.args[0][1] == 404:
                    errors.append("No remote locale for "+str(e.args[0][0])+" found. Please add it.")
                else:
                    errors.append("Problem fetching locale for "+str(e.args[0][0])+". Response code was: "+str(e.args[0][1]))
                done += 2
            except IOError as e:
                errors.append("Couldn't write "+str(e.filename)+": "+str(e.strerror))
                done += 1
            except httplib2.ServerNotFoundError as e:
                errors.append(str(e))
                done += 2
            else:
                if lang not in updated_keys:
                    updated_keys.append(lang)
    for error in errors:
        print(error)
print("Done. Updated", len(updated_keys), "languages")
