good_job = fn ->
  Process.sleep(3000)
  {:ok, []}
end

bad_job = fn ->
  Process.sleep(3000)
  :error
end

ugly_job = fn ->
  Process.sleep(2000)
  raise "error!"
end
