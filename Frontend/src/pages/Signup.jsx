import { useState } from 'react'
import { Link, Navigate, useNavigate, useSearchParams } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { usingCognito, signUp, confirmSignUp, resendCode } from '../api/auth'
import { createOrganization } from '../api/onboarding'

// Self-service sign-up in three stages:
//   1. account       - email + password  -> Cognito SignUp (Cognito emails a code)
//   2. code          - 6-digit code      -> Cognito ConfirmSignUp, then sign in
//   3. organization  - organization name -> POST /api/onboarding (user becomes OWNER)
//
// /signup?step=organization jumps straight to stage 3 (used when a signed-in
// user has no organization yet).

const inputClass =
  'w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-white text-sm focus:outline-none focus:border-blue-500'
const buttonClass =
  'w-full bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-white rounded-lg py-2 text-sm font-medium transition-colors'

/** Same rules as the Cognito password policy in Terraform/cognito.tf */
function passwordProblem(pw) {
  if (pw.length < 10) return 'Use at least 10 characters'
  if (!/[a-z]/.test(pw)) return 'Include a lowercase letter'
  if (!/[A-Z]/.test(pw)) return 'Include an uppercase letter'
  if (!/[0-9]/.test(pw)) return 'Include a number'
  return null
}

export default function Signup() {
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const { token, login } = useAuth()

  const [stage, setStage] = useState(params.get('step') === 'organization' ? 'organization' : 'account')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [code, setCode] = useState('')
  const [orgName, setOrgName] = useState('')
  const [displayName, setDisplayName] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState(null)
  const [info, setInfo] = useState(null)

  // Sign-up needs Cognito; stage 3 needs a signed-in user
  if (!usingCognito) return <Navigate to="/login" replace />
  if (stage === 'organization' && !token) return <Navigate to="/login" replace />

  const run = async (work) => {
    setBusy(true)
    setError(null)
    try {
      await work()
    } catch (err) {
      setError(err.response?.data?.error || err.message || 'Something went wrong — please try again')
    } finally {
      setBusy(false)
    }
  }

  const submitAccount = (e) => {
    e.preventDefault()
    const problem = passwordProblem(password)
    if (problem) {
      setError(problem)
      return
    }
    run(async () => {
      await signUp(email.trim(), password)
      setInfo(`We emailed a 6-digit code to ${email.trim()}`)
      setStage('code')
    })
  }

  const submitCode = (e) => {
    e.preventDefault()
    run(async () => {
      await confirmSignUp(email.trim(), code)
      const ok = await login(email.trim(), password)   // sign in right away
      if (!ok) {
        navigate('/login')
        return
      }
      setInfo(null)
      setStage('organization')
    })
  }

  const resend = () =>
    run(async () => {
      await resendCode(email.trim())
      setInfo(`We sent a new code to ${email.trim()}`)
    })

  const submitOrganization = (e) => {
    e.preventDefault()
    run(async () => {
      await createOrganization(orgName.trim(), displayName.trim() || null)
      navigate('/')
    })
  }

  const titles = {
    account: 'Create your account',
    code: 'Verify your email',
    organization: 'Name your organization',
  }

  return (
    <div className="min-h-screen bg-gray-950 flex items-center justify-center">
      <div className="w-full max-w-sm">

        <div className="text-center mb-8">
          <div className="text-4xl mb-3">⚡</div>
          <h1 className="text-white text-2xl font-semibold">Energy Monitor</h1>
          <p className="text-gray-400 text-sm mt-1">{titles[stage]}</p>
        </div>

        <div className="bg-slate-900 border border-gray-800 rounded-2xl p-6">

          {stage === 'account' && (
            <form onSubmit={submitAccount} className="space-y-4">
              <div>
                <label className="block text-xs text-gray-400 mb-1">Email</label>
                <input type="email" autoComplete="email" required className={inputClass}
                       value={email} onChange={e => setEmail(e.target.value)} placeholder="you@company.com" />
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">Password</label>
                <input type="password" autoComplete="new-password" required className={inputClass}
                       value={password} onChange={e => setPassword(e.target.value)} />
                <p className="text-xs text-gray-500 mt-1">At least 10 characters, with upper- and lowercase letters and a number</p>
              </div>
              {error && <p className="text-red-400 text-xs">{error}</p>}
              <button type="submit" disabled={busy} className={buttonClass}>
                {busy ? 'Creating account...' : 'Create account'}
              </button>
            </form>
          )}

          {stage === 'code' && (
            <form onSubmit={submitCode} className="space-y-4">
              {info && <p className="text-green-400 text-xs">{info}</p>}
              <div>
                <label className="block text-xs text-gray-400 mb-1">Verification code</label>
                <input inputMode="numeric" autoComplete="one-time-code" required className={inputClass}
                       value={code} onChange={e => setCode(e.target.value)} placeholder="123456" />
              </div>
              {error && <p className="text-red-400 text-xs">{error}</p>}
              <button type="submit" disabled={busy} className={buttonClass}>
                {busy ? 'Verifying...' : 'Verify and continue'}
              </button>
              <button type="button" onClick={resend} disabled={busy}
                      className="w-full text-xs text-gray-400 hover:text-white">
                Send the code again
              </button>
            </form>
          )}

          {stage === 'organization' && (
            <form onSubmit={submitOrganization} className="space-y-4">
              <div>
                <label className="block text-xs text-gray-400 mb-1">Organization name</label>
                <input required maxLength={120} className={inputClass}
                       value={orgName} onChange={e => setOrgName(e.target.value)} placeholder="Acme Offices" />
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">Your name (optional)</label>
                <input maxLength={120} className={inputClass}
                       value={displayName} onChange={e => setDisplayName(e.target.value)} placeholder="Jane Doe" />
              </div>
              {error && <p className="text-red-400 text-xs">{error}</p>}
              <button type="submit" disabled={busy} className={buttonClass}>
                {busy ? 'Creating...' : 'Create organization'}
              </button>
            </form>
          )}
        </div>

        {stage === 'account' && (
          <p className="text-center text-xs text-gray-500 mt-4">
            Already have an account? <Link to="/login" className="text-blue-400 hover:text-blue-300">Sign in</Link>
          </p>
        )}
      </div>
    </div>
  )
}