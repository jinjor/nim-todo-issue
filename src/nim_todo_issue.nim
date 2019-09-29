import osproc
import re
import strutils
import httpClient
import json
import terminal
import parseopt

type
  Options = object
    ownerAndRepo*: string
    dirPath*: string
    token*: string
    keyword*: string
    check*: bool
  GitHubIssue* = object
    number*: int
    isPullRequest*: bool
    isOpen*: bool
  Issue* = object
    number*: int
    file*: string
    raw*: string


proc getOptions*(args: string = ""): Options =
  proc writeHelp() =
    echo "Usage: nim_todo_issue [--keyword=TODO] [--token=xxxxx] owner/repo [src_dir]"
    quit 1

  var ownerAndRepo: string
  var dirPath: string
  var token: string
  var keyword: string
  var check = false

  var p = initOptParser(args)

  for kind, key, val in p.getopt():
    case kind
    of cmdArgument:
      if ownerAndRepo == "":
        ownerAndRepo = key
      elif dirPath == "":
        dirPath = key
      else:
        writeHelp()
    of cmdLongOption, cmdShortOption:
      case key
      of "token":
        token = val
      of "keyword":
        keyword = val
      of "check":
        check = true
      else:
        writeHelp()
    of cmdEnd:
      discard
  if ownerAndRepo == "":
    writeHelp()
  if dirPath == "":
    dirPath = "."
  if keyword == "":
    keyword = "TODO"
  return Options(ownerAndRepo: ownerAndRepo, dirPath: dirPath, token: token,
      keyword: keyword, check: check)


proc getAllGitHubIssues*(ownerAndRepo: string, token: string = ""): seq[GitHubIssue] =
  let client = newHttpClient()
  var currentPage = 1
  var lastPage: int
  if token != "":
    client.headers = newHttpHeaders({"Authorization": "token " & token})
  var url = "https://api.github.com/repos/" & ownerAndRepo & "/issues?state=all&direction=asc&per_page=100"
  var issues = newSeq[GitHubIssue]()
  while url != "":
    if lastPage > 0:
      stdout.write("Fetching... " & $currentPage & " / " & $lastPage & "\r")
      stdout.flushFile
    else:
      stdout.write("Fetching... \r")
      stdout.flushFile
    let response = client.request(url, httpMethod = HttpGet)
    if code(response) != Http200:
      raise newException(IOError, "Failed to fetch from " & url & ": " &
          $response.status)
    let jsonNode = parseJson(response.body)
    for item in jsonNode.elems:
      let number = item["number"].getInt
      let isPullRequest = item.hasKey("pull_request")
      let isOpen = item["state"].str == "open"
      issues.add(GitHubIssue(number: number, isPullRequest: isPullRequest,
        isOpen: isOpen))

    url = ""
    if not response.headers.hasKey "Link":
      continue
    let link = response.headers["Link"]
    for item in link.split(","):
      if item.endsWith("rel=\"next\""):
        let (s, e) = findBounds(item, rex"<[^>]+>")
        url = item.substr(s + 1, e - 1)
      elif item.endsWith("rel=\"last\""):
        let (s, e) = findBounds(item, rex"<[^>]+>")
        let u = item.substr(s + 1, e - 1)
        lastPage = parseInt(u.split("&page=")[1])
    currentPage = currentPage + 1

  echo "Fetched ", issues.len, " issues from GitHub."
  return issues


proc searchIssues*(keyword: string, path: string): seq[Issue] =
  let regex = keyword & r".*#\d+"
  let output = execProcess("grep -rE \"" & regex & "\" " & path)
  var issues = newSeq[Issue]()
  for line in splitLines(output):
    let words = split(line, re":")
    if words.len <= 0:
      continue
    let file = words[0]
    for issueNumber in findAll(line, re"(\d+)"): # TODO
      let number: int = parseInt(issueNumber)
      if number <= 0:
        continue
      issues.add(Issue(number: number, file: file, raw: line))
  return issues


proc report*(githubIssues: seq[GitHubIssue], issues: seq[Issue],
    check: bool): int =
  var errors = 0
  for issue in issues:
    if issue.number > githubIssues.len:
      stdout.styledWrite(fgRed, "❔ #" & $issue.number &
          " [NOT FOUND]          " & issue.raw & "\n")
      continue
    let githubIssue = githubIssues[issue.number - 1]
    let tipe = if githubIssue.isPullRequest: " [PR]       " else: " [ISSUE]    "
    if githubIssue.isOpen:
      echo "📝 #", issue.number, tipe, " [OPEN]   ", issue.raw
    else:
      stdout.styledWrite(fgYellow, "❗️ #" & $issue.number, tipe,
          " [CLOSED] ", issue.raw, "\n")
      errors += 1
  if check:
    return errors

when isMainModule:
  let
    o = getOptions()
    gitHubIssue = getAllGitHubIssues(o.ownerAndRepo, o.token)
    issues = searchIssues(o.keyword, o.dirPath)
    status = report(gitHubIssue, issues, o.check)
  quit status
